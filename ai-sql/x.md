```ts
import sql from "mssql";
import { OpenAIClient, AzureKeyCredential } from "@azure/openai";

// ─── Config ───────────────────────────────────────────────────────────────────

const DB_CONFIG: sql.config = {
	server: process.env.DB_SERVER!,
	database: process.env.DB_NAME!,
	user: process.env.DB_USER!,
	password: process.env.DB_PASSWORD!,
	options: { encrypt: true, trustServerCertificate: false },
};

const AI_CLIENT = new OpenAIClient(
	process.env.AZURE_OPENAI_ENDPOINT!, // e.g. https://your-resource.openai.azure.com/
	new AzureKeyCredential(process.env.AZURE_OPENAI_KEY!),
);
const DEPLOYMENT = process.env.AZURE_OPENAI_DEPLOYMENT!; // e.g. "gpt-4o"

// ─── Types ────────────────────────────────────────────────────────────────────

interface SchemaTable {
	tableName: string;
	columns: { name: string; type: string; nullable: boolean }[];
}

interface QueryResult {
	sql: string;
	rows: Record<string, unknown>[];
	summary: string;
}

// ─── Step 1: Fetch schema dynamically from INFORMATION_SCHEMA ─────────────────
// This runs once at startup (or can be cached/refreshed on a schedule).
// Works for any number of tables — no hardcoding needed.

async function fetchSchema(pool: sql.ConnectionPool): Promise<SchemaTable[]> {
	const result = await pool.request().query(`
    SELECT
      t.TABLE_NAME,
      c.COLUMN_NAME,
      c.DATA_TYPE,
      c.IS_NULLABLE
    FROM INFORMATION_SCHEMA.TABLES t
    JOIN INFORMATION_SCHEMA.COLUMNS c ON t.TABLE_NAME = c.TABLE_NAME
    WHERE t.TABLE_TYPE = 'BASE TABLE'
      AND t.TABLE_SCHEMA = 'dbo'   -- adjust schema if needed
    ORDER BY t.TABLE_NAME, c.ORDINAL_POSITION
  `);

	// Group columns by table
	const tableMap = new Map<string, SchemaTable>();
	for (const row of result.recordset) {
		if (!tableMap.has(row.TABLE_NAME)) {
			tableMap.set(row.TABLE_NAME, { tableName: row.TABLE_NAME, columns: [] });
		}
		tableMap.get(row.TABLE_NAME)!.columns.push({
			name: row.COLUMN_NAME,
			type: row.DATA_TYPE,
			nullable: row.IS_NULLABLE === "YES",
		});
	}

	return Array.from(tableMap.values());
}

// ─── Step 2: Format schema into a compact prompt string ───────────────────────
// Keeps token usage low — only names and types, no actual row data.
// Example output:
//   costs (id int, description varchar, amount decimal, incurred_date date)
//   projects (id int, name varchar, budget decimal)

function formatSchemaForPrompt(tables: SchemaTable[]): string {
	return tables
		.map((t) => {
			const cols = t.columns.map((c) => `${c.name} ${c.type}${c.nullable ? "?" : ""}`).join(", ");
			return `${t.tableName} (${cols})`;
		})
		.join("\n");
}

// ─── Step 3: Ask AI to generate SQL from natural language ─────────────────────

async function generateSQL(userQuestion: string, schemaPrompt: string): Promise<string> {
	const response = await AI_CLIENT.getChatCompletions(DEPLOYMENT, [
		{
			role: "system",
			content: `
You are a MSSQL query assistant for an incurred cost tracking system.
You have read-only access. ONLY generate SELECT statements — never INSERT, UPDATE, DELETE, DROP, or DDL.

The database schema is:
${schemaPrompt}

Rules:
- Respond with a single valid MSSQL SELECT query only.
- No markdown, no explanation, no backticks — raw SQL only.
- Use TOP instead of LIMIT for row limits.
- If the question cannot be answered with the available schema, respond with: UNABLE_TO_QUERY
      `.trim(),
		},
		{ role: "user", content: userQuestion },
	]);

	return response.choices[0].message?.content?.trim() ?? "UNABLE_TO_QUERY";
}

// ─── Step 4: Execute the AI-generated SQL safely ──────────────────────────────
// - Only allows SELECT statements (guards against prompt injection)
// - Returns raw rows for the next step

async function executeSQL(pool: sql.ConnectionPool, generatedSQL: string): Promise<Record<string, unknown>[]> {
	// Safety check — reject anything that isn't a SELECT
	const normalized = generatedSQL.trim().toUpperCase();
	if (!normalized.startsWith("SELECT")) {
		throw new Error(`Unsafe or invalid SQL rejected: ${generatedSQL}`);
	}

	const result = await pool.request().query(generatedSQL);
	return result.recordset;
}

// ─── Step 5: Send results back to AI for a plain-English summary ──────────────
// This is the second turn — AI now sees both the question and the actual data.

async function summarizeResults(
	userQuestion: string,
	generatedSQL: string,
	rows: Record<string, unknown>[],
): Promise<string> {
	const response = await AI_CLIENT.getChatCompletions(DEPLOYMENT, [
		{
			role: "system",
			content:
				"You are a helpful assistant that summarizes database query results in clear, concise business language.",
		},
		{
			role: "user",
			content: `
The user asked: "${userQuestion}"

The following SQL was run:
${generatedSQL}

The results were:
${JSON.stringify(rows, null, 2)}

Please summarize the results in 2–4 sentences, highlighting the most important numbers or trends.
      `.trim(),
		},
	]);

	return response.choices[0].message?.content?.trim() ?? "No summary available.";
}

// ─── Main orchestrator ────────────────────────────────────────────────────────

async function askQuestion(
	userQuestion: string,
	pool: sql.ConnectionPool,
	schema: SchemaTable[], // pass cached schema — don't re-fetch every query
): Promise<QueryResult> {
	const schemaPrompt = formatSchemaForPrompt(schema);

	// Turn 1: Generate SQL
	const generatedSQL = await generateSQL(userQuestion, schemaPrompt);

	if (generatedSQL === "UNABLE_TO_QUERY") {
		return {
			sql: "",
			rows: [],
			summary: "Sorry, that question can't be answered with the available data.",
		};
	}

	// Execute against MSSQL
	const rows = await executeSQL(pool, generatedSQL);

	// Turn 2: Summarize results
	const summary = await summarizeResults(userQuestion, generatedSQL, rows);

	return { sql: generatedSQL, rows, summary };
}

// ─── Entry point example ──────────────────────────────────────────────────────

async function main() {
	const pool = await sql.connect(DB_CONFIG);
	console.log("Connected to MSSQL");

	// Fetch and cache schema once at startup
	const schema = await fetchSchema(pool);
	console.log(`Schema loaded: ${schema.length} tables`);

	// Example questions
	const questions = [
		"What are the top 5 vendors by total incurred cost this year?",
		"Which projects are over budget?",
		"Show me monthly cost totals for the last 6 months",
	];

	for (const q of questions) {
		console.log(`\nQuestion: ${q}`);
		const result = await askQuestion(q, pool, schema);
		console.log(`SQL:     ${result.sql}`);
		console.log(`Rows:    ${result.rows.length} returned`);
		console.log(`Summary: ${result.summary}`);
	}

	await pool.close();
}

main().catch(console.error);
```
