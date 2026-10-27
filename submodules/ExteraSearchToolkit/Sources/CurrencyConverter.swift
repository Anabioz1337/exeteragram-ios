import Foundation
import TelegramUIPreferences

public struct ExteraRatesSnapshot {
    public let fiatPerUsd: [String: Double]
    public let cryptoUsd: [String: Double]

    public init(fiatPerUsd: [String: Double], cryptoUsd: [String: Double]) {
        self.fiatPerUsd = fiatPerUsd
        self.cryptoUsd = cryptoUsd
    }

    public static let empty = ExteraRatesSnapshot(fiatPerUsd: [:], cryptoUsd: [:])

    private func fiatRateToUsd(_ currency: String) -> Double? {
        if currency.uppercased() == "USD" {
            return 1.0
        }
        return self.fiatPerUsd[currency.uppercased()] ?? ExteraCurrencySupport.fallbackRate(currency: currency, against: "USD")
    }

    public func fiatRate(currency: String, against base: String) -> Double? {
        if base.uppercased() == "USD" {
            return self.fiatRateToUsd(currency)
        }
        guard let baseRate = self.fiatRateToUsd(base), let currencyRate = self.fiatRateToUsd(currency) else {
            return nil
        }
        return currencyRate / baseRate
    }
}

struct ExteraAmountKind {
    enum Kind: Equatable {
        case fiat(String)
        case crypto(String)
        case stars
    }

    let kind: Kind
    let title: String
}

public enum ExteraCurrencyConverter {
    private static let cryptoAliases: [String: String] = [
        "btc": "BTC", "bitcoin": "BTC",
        "eth": "ETH", "ethereum": "ETH",
        "ton": "TON", "toncoin": "TON"
    ]

    private static let approximateStarUsdPrice = 0.02

    private static func recognize(kindToken word: String) -> ExteraAmountKind? {
        let lowered = word.lowercased()
        if lowered == "stars" || lowered == "star" || lowered == "xtr" {
            return ExteraAmountKind(kind: .stars, title: "XTR")
        }
        if ExteraCurrencySupport.isValidIsoCode(lowered) {
            return ExteraAmountKind(kind: .fiat(lowered.uppercased()), title: lowered.uppercased())
        }
        if let symbolValue = ExteraCurrencySupport.currencyForSymbol(lowered) {
            return ExteraAmountKind(kind: .fiat(symbolValue), title: symbolValue)
        }
        if let cryptoId = cryptoAliases[lowered] {
            return ExteraAmountKind(kind: .crypto(cryptoId), title: cryptoId)
        }
        return nil
    }

    private static func amountMultiplier(_ word: String) -> Double {
        if word.hasSuffix("k"), Double(word.dropLast()) != nil {
            return 1000.0
        }
        return 1.0
    }

    public static func convert(
        query: String,
        defaultCurrency: String,
        rates: ExteraRatesSnapshot
    ) -> (resultText: String, value: Double)? {
        let words = query.lowercased().split(whereSeparator: { $0 == " " }).map(String.init)

        var amountIndex: Int?
        var amountValue: Double?
        for (index, word) in words.enumerated() {
            if word.hasSuffix("k"), let numeric = Double(word.dropLast()) {
                amountIndex = index
                amountValue = numeric * 1000.0
                break
            }
            if let numeric = Double(word) {
                amountIndex = index
                amountValue = numeric
                break
            }
        }
        guard let amountIndex, let amount = amountValue else {
            return nil
        }

        let followingWords = Array(words[(amountIndex + 1)...])
        var kindCandidates: [ExteraAmountKind] = []
        for word in followingWords where kindCandidates.count < 2 {
            if word == "to" || word == "in" || word == "as" {
                continue
            }
            if let kind = recognize(kindToken: word) {
                kindCandidates.append(kind)
            }
        }
        if kindCandidates.isEmpty && amountIndex > 0 {
            for word in words[..<amountIndex].reversed() {
                if let kind = recognize(kindToken: word) {
                    kindCandidates.insert(kind, at: 0)
                    break
                }
            }
        }

        let sourceKind = kindCandidates.first ?? ExteraAmountKind(kind: .fiat(defaultCurrency.uppercased()), title: defaultCurrency.uppercased())
        let resolvedTarget: ExteraAmountKind
        if kindCandidates.count >= 2 {
            resolvedTarget = kindCandidates.last!
        } else {
            resolvedTarget = ExteraAmountKind(kind: .fiat(defaultCurrency.uppercased()), title: defaultCurrency.uppercased())
        }

        guard let conversion = convertedAmount(amount: amount, from: sourceKind, to: resolvedTarget, rates: rates) else {
            return nil
        }
        let rendered = ExteraResultFormatter.format(conversion.value, groupDigits: false)
        return ("\(rendered) \(resolvedTarget.title)", conversion.value)
    }

    private static func convertedAmount(amount: Double, from: ExteraAmountKind, to: ExteraAmountKind, rates: ExteraRatesSnapshot) -> (value: Double)? {
        switch (from.kind, to.kind) {
        case let (.fiat(sourceCode), .fiat(targetCode)):
            guard let rate = rates.fiatRate(currency: targetCode, against: sourceCode) else {
                return nil
            }
            return amount * rate
        case let (.crypto(coinId), .fiat(targetCode)):
            guard let usdPrice = rates.cryptoUsd[coinId], let rate = rates.fiatRate(currency: targetCode, against: "USD") else {
                return nil
            }
            return amount * usdPrice * rate
        case let (.fiat(sourceCode), .crypto(coinId)):
            guard let usdPrice = rates.cryptoUsd[coinId], let rate = rates.fiatRate(currency: sourceCode, against: "USD") else {
                return nil
            }
            return amount * rate / usdPrice
        case let (.crypto(sourceCoin), .crypto(targetCoin)):
            guard let sourceUsd = rates.cryptoUsd[sourceCoin], let targetUsd = rates.cryptoUsd[targetCoin] else {
                return nil
            }
            return amount * sourceUsd / targetUsd
        case (.stars, .fiat(let targetCode)):
            guard let rate = rates.fiatRate(currency: targetCode, against: "USD") else {
                return nil
            }
            return amount * starConversionBase() * rate
        case (.fiat(let sourceCode), .stars):
            guard let rate = rates.fiatRate(currency: sourceCode, against: "USD") else {
                return nil
            }
            return amount * rate / starConversionBase()
        case (.stars, .crypto(let coinId)):
            guard let coinUsd = rates.cryptoUsd[coinId] else {
                return nil
            }
            return amount * starConversionBase() / coinUsd
        case (.crypto(let coinId), .stars):
            guard let coinUsd = rates.cryptoUsd[coinId] else {
                return nil
            }
            return amount * coinUsd / starConversionBase()
        }
    }

    /// Telegram prices Stars in dollar terms and CoinGecko has no direct XTR market, so conversions
    /// go through the round dollar price a user actually pays per star.
    private static func starConversionBase() -> Double {
        return approximateStarUsdPrice
    }
}
