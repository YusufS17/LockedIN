import Foundation

// MARK: - Money Types

/// The canonical money type for LockedIN.
/// All monetary fields use `Pence` (Int) — 500 == £5.00.
/// FORBIDDEN: Double, Float, Decimal for any money storage or computation.
typealias Pence = Int

/// Alias of Pence; both names exist because ROADMAP/CONTEXT use both.
typealias MinorUnits = Int

// MARK: - Display-Boundary Formatter

/// The SINGLE display-boundary function that converts a `Pence` value to a
/// formatted currency string. This is the ONLY place `Pence -> String`
/// conversion happens (D-08). MoneyLabel is the exclusive consumer.
///
/// Examples:
/// - `formatPence(500)` → `"£5.00"`
/// - `formatPence(50)`  → `"£0.50"`
/// - `formatPence(2000)` → `"£20.00"`
/// - `formatPence(1500)` → `"£15.00"`
func formatPence(_ amount: Pence, currencyCode: String = "GBP") -> String {
    // Use integer arithmetic to guarantee exact 2 decimal places.
    // Never trim whole-pound amounts (D-07).
    let pounds = abs(amount) / 100
    let pence = abs(amount) % 100
    let sign = amount < 0 ? "-" : ""

    // Determine symbol from currency code.
    let symbol: String
    switch currencyCode {
    case "GBP": symbol = "£"
    case "USD": symbol = "$"
    case "EUR": symbol = "€"
    default:    symbol = currencyCode + " "
    }

    // WR-05 fix: keep dynamic values (sign, symbol) out of the format string.
    // Interpolating them into the format string would allow any `%` in a currency
    // symbol/code to be mis-interpreted as a conversion specifier by String(format:).
    let amountString = String(format: "%d.%02d", pounds, pence)
    return sign + symbol + amountString
}
