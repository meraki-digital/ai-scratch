/**
 * String Utilities
 * Copy what you need - no dependencies required
 */

// Capitalize first letter of a string
export function capitalize(str: string): string {
  if (!str) return str;
  return str.charAt(0).toUpperCase() + str.slice(1);
}

// Capitalize first letter of each word
export function titleCase(str: string): string {
  if (!str) return str;
  return str
    .toLowerCase()
    .split(" ")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

// Truncate string with ellipsis
export function truncate(str: string, maxLength: number, suffix = "..."): string {
  if (!str || str.length <= maxLength) return str;
  return str.slice(0, maxLength - suffix.length) + suffix;
}

// Convert string to URL-friendly slug
export function slugify(str: string): string {
  return str
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, "") // Remove non-word chars
    .replace(/[\s_-]+/g, "-") // Replace spaces/underscores with hyphens
    .replace(/^-+|-+$/g, ""); // Remove leading/trailing hyphens
}

// Convert camelCase to kebab-case
export function camelToKebab(str: string): string {
  return str.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase();
}

// Convert kebab-case to camelCase
export function kebabToCamel(str: string): string {
  return str.replace(/-([a-z])/g, (_, letter) => letter.toUpperCase());
}

// Convert snake_case to camelCase
export function snakeToCamel(str: string): string {
  return str.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
}

// Convert camelCase to snake_case
export function camelToSnake(str: string): string {
  return str.replace(/([a-z])([A-Z])/g, "$1_$2").toLowerCase();
}

// Strip HTML tags from string
export function stripHtml(str: string): string {
  return str.replace(/<[^>]*>/g, "");
}

// Escape HTML special characters
export function escapeHtml(str: string): string {
  const map: Record<string, string> = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#039;",
  };
  return str.replace(/[&<>"']/g, (char) => map[char]);
}

// Generate random string (alphanumeric)
export function randomString(length: number): string {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let result = "";
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

// Check if string is empty or whitespace only
export function isBlank(str: string | null | undefined): boolean {
  return !str || str.trim().length === 0;
}

// Reverse a string
export function reverse(str: string): string {
  return str.split("").reverse().join("");
}

// Count occurrences of substring
export function countOccurrences(str: string, substring: string): number {
  if (!substring) return 0;
  return (str.match(new RegExp(substring, "g")) || []).length;
}

// Pad string to length (left)
export function padLeft(str: string, length: number, char = " "): string {
  return str.padStart(length, char);
}

// Pad string to length (right)
export function padRight(str: string, length: number, char = " "): string {
  return str.padEnd(length, char);
}
