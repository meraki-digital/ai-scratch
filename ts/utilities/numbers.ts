/**
 * Number Utilities
 * Copy what you need - no dependencies required
 */

// Format number with comma separators and optional decimal places
export function numberWithCommas(num: number, decimalPlaces?: number): string {
  // Handle decimal places if specified
  const fixedNum = decimalPlaces !== undefined ? num.toFixed(decimalPlaces) : num.toString();

  // Split into integer and decimal parts
  const [integerPart, decimalPart] = fixedNum.split(".");

  // Add commas to integer part
  const withCommas = integerPart.replace(/\B(?=(\d{3})+(?!\d))/g, ",");

  // Rejoin with decimal part if exists
  return decimalPart !== undefined ? `${withCommas}.${decimalPart}` : withCommas;
}
