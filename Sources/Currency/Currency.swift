//
//  Currency.swift
//
//
//  Created by Athanasios Papazoglou on 1/2/24.
//

import Foundation

/// A class that encapsulates currency information and provides formatting utilities.
///
/// Use this class to represent a specific currency configuration and format monetary amounts
/// according to the currency's locale, symbol, decimal notation, and grouping rules.
/// Configuration is loaded from a bundled JSON file selected by `countryCode` (uppercased) and
/// the first two characters of `languageSysname` (the language code), e.g. `"GR-el.json"`.
open class Currency {
    /// The model containing additional details about the currency, such as locale, symbol, etc.
    private(set) var model: CurrencyModel?
    
    /// The alpha-2 country code for the currency.
    ///
    /// For ex. `GR` or `US`.
    public var countryCode: String
    
    /// The language sysname associated with the currency in the format "languageCode-CountryCode".
    ///
    /// For ex. `el-GR`
    public var languageSysname: String
    
    /// The getter for the currency symbol from the currency model
    public var currencySymbol: String? {
        return model?.currencySymbol
    }
    
    /// Initializes a new instance of the `Currency` class.
    ///
    /// - Parameters:
    ///   - countryCode: The alpha-2 country code for the currency.
    ///   - languageSysname: The language sysname for the currency in the format "languageCode-CountryCode".
    public init(countryCode: String, languageSysname: String) {
        self.countryCode = countryCode
        self.languageSysname = languageSysname
        self.loadCurrencyData()
    }
    
    /// Initializes a new instance of the `Currency` class.
    ///
    /// - Parameters:
    ///   - currencyModel: The already downloaded CurrencyModel.
    ///   - lang: The language sysname for the currency in the format "languageCode-CountryCode".
    public init(currencyModel: CurrencyModel) {
        self.countryCode = currencyModel.countryCode
        self.model = currencyModel
        self.languageSysname = currencyModel.locale
    }
    
    // MARK: Public Methods
    
    /// Refreshes currency information by fetching data from a JSON file associated with the
    /// country code and language sysname.
    public func refresh() {
        loadCurrencyData()
    }
    
    /// Returns the formatted currency string for the given amount.
    ///
    /// - Parameter amount: The amount to format.
    /// - Returns: A formatted currency string including the currency symbol, or `nil` if formatting fails.
    public func currencyFormat(amount: Double) -> String? {
        let numberFormatter = NumberFormatter()
        let amountNSNumber = NSNumber(floatLiteral: amount)
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = model?.currencySymbol
        numberFormatter.currencyDecimalSeparator = model?.decimalNotation.rawValue
        numberFormatter.currencyGroupingSeparator = model?.groupingNotation.rawValue
        numberFormatter.locale = Locale(identifier: languageSysname)
        return numberFormatter.string(from: amountNSNumber)
    }


    /// Returns the formatted currency string for the given amount without a currency symbol.
    ///
    /// Useful when the symbol is displayed separately in the UI.
    ///
    /// - Parameter amount: The amount to format using the currency's locale settings.
    /// - Returns: A locale-formatted numeric string with no currency symbol, or `nil` if formatting fails.
    public func localeFormat(amount: Double) -> String? {
        let numberFormatter = NumberFormatter()
        let amountNSNumber = NSNumber(floatLiteral: amount)
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = ""
        numberFormatter.currencyDecimalSeparator = model?.decimalNotation.rawValue
        numberFormatter.currencyGroupingSeparator = model?.groupingNotation.rawValue
        numberFormatter.locale = Locale(identifier: languageSysname)
        return numberFormatter.string(from: amountNSNumber)?.trimmingCharacters(in: .whitespaces)
    }
    /// Returns the formatted currency string for the given amount, omitting unnecessary trailing zeroes.
    ///
    /// Fractional digits are shown only when non-zero, up to a maximum of 2 decimal places.
    ///
    /// - Parameter amount: The amount to format.
    /// - Returns: A formatted currency string, or `nil` if formatting fails.
    public func currencyFormatWithoutTrailingZeroes(amount: Double) -> String? {
        let numberFormatter = NumberFormatter()
        let amountNSNumber = NSNumber(floatLiteral: amount)
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = model?.currencySymbol
        numberFormatter.currencyDecimalSeparator = model?.decimalNotation.rawValue
        numberFormatter.currencyGroupingSeparator = model?.groupingNotation.rawValue
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.locale = Locale(identifier: languageSysname)
        return numberFormatter.string(from: amountNSNumber)
    }
    
    /// Returns the formatted currency string for the given amount with a configurable number of trailing zeroes.
    ///
    /// - Parameters:
    ///   - amount: The amount to format.
    ///   - minTrailingZeroes: The minimum number of fractional digits to display.
    ///   - maxTrailingZeroes: The maximum number of fractional digits to display.
    /// - Returns: A formatted currency string, or `nil` if formatting fails.
    public func currencyFormatWithTrailingZeroes(amount: Double, minTrailingZeroes: Int, maxTrailingZeroes: Int) -> String? {
        let numberFormatter = NumberFormatter()
        let amountNSNumber = NSNumber(floatLiteral: amount)
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = model?.currencySymbol
        numberFormatter.currencyDecimalSeparator = model?.decimalNotation.rawValue
        numberFormatter.currencyGroupingSeparator = model?.groupingNotation.rawValue
        numberFormatter.minimumFractionDigits = minTrailingZeroes
        numberFormatter.maximumFractionDigits = maxTrailingZeroes
        numberFormatter.locale = Locale(identifier: languageSysname)
        return numberFormatter.string(from: amountNSNumber)
    }
    
    /// Removes the currency symbol from the given string
    ///
    /// - Parameter string: the string from which to remove the currency symbol
    public func removeCurrency(from string: String) -> String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = model?.currencySymbol
        numberFormatter.currencyDecimalSeparator = model?.decimalNotation.rawValue
        numberFormatter.currencyGroupingSeparator = model?.groupingNotation.rawValue
        numberFormatter.locale = Locale(identifier: languageSysname)
        guard let number = numberFormatter.number(from: string) else { return nil }
        return "\(number)"
    }
    
    // MARK: Private Methods
    
    /// Fetches currency information from a JSON file located in the module bundle.
    ///
    /// The JSON file is looked up by combining `countryCode` (uppercased) and the first two
    /// characters of `languageSysname` (lowercased language code), e.g. `"GR-el.json"`.
    ///
    private func loadCurrencyData() {
        guard let fileURL = Bundle.module.url(forResource: "\(countryCode.uppercased())-\(languageSysname.prefix(2).lowercased())", withExtension: "json") else { return }
        guard let jsonData = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        let model = try? decoder.decode(CurrencyModel.self, from: jsonData)
        self.model = model
    }
}
