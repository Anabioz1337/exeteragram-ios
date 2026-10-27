import Foundation

public enum ExteraCurrencySupport {
    public static let isoCodes = ["usd", "eur", "gbp", "jpy", "cny", "rub", "uah", "kzt", "inr", "try", "brl", "cad", "aud", "chf", "pln", "czk", "sek", "nok", "dkk", "huf", "ron", "zar", "krw", "sgd", "hkd", "nzd", "thb", "idr", "php", "vnd", "ils", "aed", "sar", "egp", "mad", "mxn", "ars", "clp", "cop", "pkr", "bdt"]

    public static let starsApiId = "stars"

    private static let countryToCurrency: [String: String] = [
        "US": "USD", "EC": "USD", "SV": "USD", "PA": "USD",
        "EU": "EUR", "DE": "EUR", "FR": "EUR", "IT": "EUR", "ES": "EUR", "NL": "EUR", "BE": "EUR", "AT": "EUR", "PT": "EUR", "IE": "EUR", "FI": "EUR", "GR": "EUR", "SK": "EUR", "SI": "EUR", "LT": "EUR", "LV": "EUR", "EE": "EUR", "LU": "EUR", "CY": "EUR", "MT": "EUR", "HR": "EUR",
        "GB": "GBP", "JP": "JPY", "CN": "CNY", "RU": "RUB", "UA": "UAH", "KZ": "KZT", "BY": "BYN", "IN": "INR", "TR": "TRY", "BR": "BRL", "CA": "CAD", "AU": "AUD", "NZ": "NZD", "CH": "CHF", "PL": "PLN", "CZ": "CZK", "SE": "SEK", "NO": "NOK", "DK": "DKK", "HU": "HUF", "RO": "RON", "ZA": "ZAR", "KR": "KRW", "SG": "SGD", "HK": "HKD", "TH": "THB", "ID": "IDR", "PH": "PHP", "VN": "VND", "IL": "ILS", "AE": "AED", "SA": "SAR", "EG": "EGP", "MA": "MAD", "MX": "MXN", "AR": "ARS", "CL": "CLP", "CO": "COP", "PK": "PKR", "BD": "BDT"
    ]

    private static let phoneCodeToCountry: [String: String] = [
        "1": "US", "7": "RU", "20": "EG", "27": "ZA", "30": "GR", "31": "NL", "32": "BE", "33": "FR", "34": "ES", "36": "HU", "39": "IT", "40": "RO", "41": "CH", "43": "AT", "44": "GB", "45": "DK", "46": "SE", "47": "NO", "48": "PL", "49": "DE", "51": "PE", "52": "MX", "53": "CU", "54": "AR", "55": "BR", "56": "CL", "57": "CO", "58": "VE", "60": "MY", "61": "AU", "62": "ID", "63": "PH", "64": "NZ", "65": "SG", "66": "TH", "81": "JP", "82": "KR", "84": "VN", "86": "CN", "90": "TR", "91": "IN", "92": "PK", "94": "LK", "98": "IR", "211": "SS", "212": "MA", "213": "DZ", "216": "TN", "218": "LY", "220": "GM", "223": "ML", "225": "CI", "231": "LR", "232": "SL", "233": "GH", "234": "NG", "235": "TD", "236": "CF", "238": "CV", "242": "CG", "243": "CD", "244": "AO", "245": "GW", "249": "SD", "250": "RW", "251": "ET", "252": "SO", "253": "DJ", "254": "KE", "255": "TZ", "256": "UG", "257": "BI", "258": "MZ", "260": "ZM", "261": "MG", "262": "RE", "263": "ZW", "264": "NA", "265": "MW", "266": "LS", "267": "BW", "268": "SZ", "270": "XK", "271": "XK", "290": "SH", "291": "ER", "297": "AW", "298": "FO", "299": "GL", "350": "GI", "351": "PT", "352": "LU", "353": "IE", "354": "IS", "355": "AL", "356": "MT", "357": "CW", "358": "AX", "359": "BG", "370": "LT", "371": "LV", "372": "EE", "373": "MD", "374": "AM", "375": "BY", "376": "AD", "377": "MC", "378": "SM", "380": "UA", "381": "RS", "382": "ME", "383": "XK", "385": "HR", "386": "SI", "387": "BA", "389": "MK", "420": "CZ", "421": "SK", "423": "LI", "500": "FK", "501": "BZ", "502": "GT", "503": "SV", "504": "HN", "505": "NI", "506": "CR", "507": "PA", "509": "HT", "590": "GP", "591": "BO", "592": "GY", "593": "EC", "594": "GF", "595": "PY", "596": "MQ", "597": "SR", "598": "UY", "673": "BN", "675": "PG", "676": "TO", "685": "WS", "691": "FM", "692": "MH", "870": "XK", "881": "XK", "971": "AE", "972": "IL", "973": "BH", "974": "QA", "975": "BT", "976": "MN", "977": "NP", "992": "TJ", "993": "TM", "994": "AZ", "995": "GE", "996": "KG", "998": "UZ"
    ]

    private static let symbolToCurrency: [String: String] = [
        "$": "USD", "€": "EUR", "£": "GBP", "¥": "JPY", "₽": "RUB", "₴": "UAH", "₺": "TRY", "₹": "INR", "₩": "KRW", "₸": "KZT", "₪": "ILS", "₫": "VND", "C$": "CAD", "A$": "AUD", "R$": "BRL", "zł": "PLN", "kr": "SEK"
    ]

    /// Exchange rates against USD from the last bundled ECB snapshot, used until a live
    /// fetch answers (frankfurter.dev, no key) or while offline.
    private static let fallbackRatesPerUsd: [String: Double] = [
        "USD": 1.0,
        "EUR": 0.92,
        "GBP": 0.78,
        "JPY": 151.0,
        "CNY": 7.24,
        "RUB": 92.0,
        "UAH": 41.4,
        "KZT": 473.0,
        "BYN": 3.28,
        "INR": 84.0,
        "TRY": 34.4,
        "BRL": 5.72,
        "CAD": 1.36,
        "AUD": 1.52,
        "NZD": 1.66,
        "CHF": 0.88,
        "PLN": 4.0,
        "CZK": 23.2,
        "SEK": 10.5,
        "NOK": 10.6,
        "DKK": 6.87,
        "HUF": 364.0,
        "RON": 4.58,
        "ZAR": 18.3,
        "KRW": 1360.0,
        "SGD": 1.34,
        "HKD": 7.8,
        "THB": 35.0,
        "IDR": 15800.0,
        "PHP": 56.0,
        "VND": 25400.0,
        "ILS": 3.72,
        "AED": 3.67,
        "SAR": 3.75,
        "EGP": 48.5,
        "MAD": 9.9,
        "MXN": 19.4,
        "ARS": 1000.0,
        "CLP": 950.0,
        "COP": 4300.0,
        "PKR": 280.0,
        "BDT": 120.0
    ]

    public static func currencyForCurrentLocale() -> String {
        if let identifier = Locale.current.currencyCode, !identifier.isEmpty {
            return identifier
        }
        let region = Locale.current.regionCode ?? ""
        if let currency = self.countryToCurrency[region] {
            return currency
        }
        return "USD"
    }

    public static func currencyForCountryCode(_ countryCode: String) -> String? {
        return self.countryToCurrency[countryCode.uppercased()]
    }

    public static func countryForPhoneCode(_ phoneCode: String) -> String? {
        return self.phoneCodeToCountry[phoneCode]
    }

    public static func currencyForPhoneCode(_ phoneCode: String) -> String? {
        guard let country = self.countryForPhoneCode(phoneCode) else {
            return nil
        }
        return self.countryToCurrency[country]
    }

    public static func currencyForSymbol(_ symbol: String) -> String? {
        if symbol.count == 1, let single = self.symbolToCurrency[symbol] {
            return single
        }
        return self.symbolToCurrency[symbol]
    }

    public static func isValidIsoCode(_ code: String) -> Bool {
        return self.fallbackRatesPerUsd[code.uppercased()] != nil
    }

    public static func fallbackRate(currency: String, against base: String) -> Double? {
        let upperCurrency = currency.uppercased()
        let upperBase = base.uppercased()
        guard let baseRate = self.fallbackRatesPerUsd[upperBase], let currencyRate = self.fallbackRatesPerUsd[upperCurrency] else {
            return nil
        }
        return currencyRate / baseRate
    }
}
