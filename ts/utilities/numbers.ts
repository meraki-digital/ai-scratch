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

  // Handle negative sign
  const isNegative = integerPart.startsWith("-");
  const absoluteInt = isNegative ? integerPart.slice(1) : integerPart;
  const withCommas = absoluteInt.replace(/\B(?=(\d{3})+(?!\d))/g, ",");

  // Rejoin with negative sign and decimal part if exists
  return (isNegative ? "-" : "") + (decimalPart !== undefined ? `${withCommas}.${decimalPart}` : withCommas);
}
