//
//  CurrencyModel.swift
//
//
//  Created by Athanasios Papazoglou on 1/2/24.
//

import Foundation

/// A struct representing a model for currency information.
///
/// This struct contains details about a specific currency, including its country code, currency code,
/// locale, symbol, symbol position, decimal format, decimal notation, grouping notation, and spacing.
///
/// Example usage:
/// ```swift
/// let currencyInfo = CurrencyModel(
///     countryCode: "GR",
///     currencyCode: "EUR",   // optional; omit or pass nil for legacy payloads
///     locale: "el-GR",
///     currencySymbol: "€",
///     symbolPosition: .end,
///     decimalFormat: "%.2f",
///     decimalNotation: .comma,
///     groupingNotation: .dot,
///     hasCurrencySpace: true
/// )
/// ```
public struct CurrencyModel: Codable {
    /// The alpha-2 country code (e.g., `GR`, `US`).
    public let countryCode: String

    /// The ISO 4217 currency code (e.g., `EUR`, `USD`).
    ///
    /// Optional for backward compatibility: older encoded payloads or JSON files that predate
    /// this field will decode successfully and produce `nil` here rather than throwing.
    public let currencyCode: String?

    /// The locale identifier in "languageCode-CountryCode" format (e.g., `el-GR`, `en-US`).
    public let locale: String

    /// The currency symbol to display (e.g., `€`, `$`).
    public let currencySymbol: String

    /// The position of the currency symbol relative to the amount — either `.start` or `.end`.
    public let symbolPosition: CurrencySymbolPosition

    /// The format string used to represent decimal values (e.g., `"%.2f"`).
    public let decimalFormat: String

    /// The character used as the decimal separator (e.g., `.dot` for `"100.00"`, `.comma` for `"100,00"`).
    public let decimalNotation: CurrencyDecimalNotation

    /// The character used as the thousands grouping separator (e.g., `.dot` for `"1.000"`, `.comma` for `"1,000"`).
    public let groupingNotation: CurrencyDecimalNotation

    /// Whether a space should be inserted between the currency symbol and the amount.
    public let hasCurrencySpace: Bool

    /// The number of fractional digits, parsed once from `decimalFormat`.
    ///
    /// Extracts the precision from a printf-style format string such as `"%.2f"`,
    /// falling back to `0` if the format string cannot be parsed. Computed a single
    /// time at initialization rather than on every access.
    public let maximumFractionDigits: Int

    /// The keys that participate in encoding/decoding.
    ///
    /// `maximumFractionDigits` is intentionally omitted — it is derived from `decimalFormat`.
    private enum CodingKeys: String, CodingKey {
        case countryCode, currencyCode, locale, currencySymbol
        case symbolPosition, decimalFormat, decimalNotation, groupingNotation, hasCurrencySpace
    }

    /// Memberwise initializer.
    ///
    /// `maximumFractionDigits` is derived from `decimalFormat` and therefore not a parameter.
    public init(
        countryCode: String,
        currencyCode: String? = nil,
        locale: String,
        currencySymbol: String,
        symbolPosition: CurrencySymbolPosition,
        decimalFormat: String,
        decimalNotation: CurrencyDecimalNotation,
        groupingNotation: CurrencyDecimalNotation,
        hasCurrencySpace: Bool
    ) {
        self.countryCode = countryCode
        self.currencyCode = currencyCode
        self.locale = locale
        self.currencySymbol = currencySymbol
        self.symbolPosition = symbolPosition
        self.decimalFormat = decimalFormat
        self.decimalNotation = decimalNotation
        self.groupingNotation = groupingNotation
        self.hasCurrencySpace = hasCurrencySpace
        self.maximumFractionDigits = Self.fractionDigits(from: decimalFormat)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        countryCode = try container.decode(String.self, forKey: .countryCode)
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode)
        locale = try container.decode(String.self, forKey: .locale)
        currencySymbol = try container.decode(String.self, forKey: .currencySymbol)
        symbolPosition = try container.decode(CurrencySymbolPosition.self, forKey: .symbolPosition)
        decimalFormat = try container.decode(String.self, forKey: .decimalFormat)
        decimalNotation = try container.decode(CurrencyDecimalNotation.self, forKey: .decimalNotation)
        groupingNotation = try container.decode(CurrencyDecimalNotation.self, forKey: .groupingNotation)
        hasCurrencySpace = try container.decode(Bool.self, forKey: .hasCurrencySpace)
        maximumFractionDigits = Self.fractionDigits(from: decimalFormat)
    }

    /// Parses the precision out of a printf-style format string such as `"%.2f"`.
    ///
    /// - Returns: The number of fractional digits, or `0` if the string cannot be parsed.
    private static func fractionDigits(from decimalFormat: String) -> Int {
        Int(
            decimalFormat
                .drop { $0 != "." }     // "%.2f" -> ".2f"
                .dropFirst()            // ".2f"  -> "2f"
                .prefix { $0.isNumber } // "2f"   -> "2"
        ) ?? 0
    }
}
