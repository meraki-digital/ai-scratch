# SQL Templates

T-SQL (SQL Server) stored procedure templates.

## Files

- `crud-templates.sql` - Basic CRUD stored procedures

## Usage

1. Copy the procedure you need
2. Replace `[SchemaName]` with your schema (e.g., `dbo`)
3. Replace `[TableName]` with your table name
4. Adjust columns as needed

## Naming Convention

Procedures follow the pattern: `usp_TableName_Action`

- `usp_` prefix for user stored procedures
- Table name
- Action (GetById, GetAll, Insert, Update, Delete, etc.)
