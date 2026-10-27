import Foundation
import TelegramUIPreferences

public enum ExteraInlineResultKind {
    case arithmetic
    case currency
    case units
    case timezone
}

public struct ExteraInlineEvaluationResult {
    public let resultText: String
    public let kind: ExteraInlineResultKind

    init(resultText: String, kind: ExteraInlineResultKind) {
        self.resultText = resultText
        self.kind = kind
    }
}

/// The single entry point the search field drives: turns whatever was typed into the one
/// inline answer worth showing, respecting the per-feature switches.
public enum ExteraInlineResultsEvaluator {
    private static let maximalQueryLength = 96

    public static func evaluate(
        query rawQuery: String,
        settings: ExteraInlineResultsSettings,
        rates: ExteraRatesSnapshot
    ) -> ExteraInlineEvaluationResult? {
        var query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        while query.hasPrefix("=") {
            query = String(query.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        guard !query.isEmpty, query.count <= maximalQueryLength else {
            return nil
        }
        let lowered = query.lowercased()

        if settings.timeZonesEnabled, let timezoneResult = timeZoneResult(for: lowered) {
            return ExteraInlineEvaluationResult(resultText: timezoneResult, kind: .timezone)
        }

        if settings.currenciesEnabled, let currencyResult = currencyResult(for: lowered, settings: settings, rates: rates) {
            return ExteraInlineEvaluationResult(resultText: currencyResult.resultText, kind: .currency)
        }

        if settings.unitsEnabled, let unitResult = ExteraUnitConverter.convert(query: lowered, measureSystem: settings.measureSystem) {
            return ExteraInlineEvaluationResult(resultText: unitResult.formatted, kind: .units)
        }

        if settings.calculatorEnabled, looksLikeExpression(lowered), let value = try? evaluateExpression(lowered, context: ExteraEvaluationContext(angleMode: settings.angleUnit == .degrees ? .degrees : .radians)), value.isFinite {
            let rendered = ExteraResultFormatter.format(value, groupDigits: settings.digitGrouping)
            return ExteraInlineEvaluationResult(resultText: rendered, kind: .arithmetic)
        }

        return nil
    }

    private static func looksLikeExpression(_ query: String) -> Bool {
        for character in query {
            switch character {
            case "+", "-", "*", "/", "^", "%", "(", ")", "=", ",":
                return true
            default:
                continue
            }
        }
        if ["sin(", "cos(", "tan(", "sqrt(", "log(", "ln(", "abs(", "exp("].contains(where: { query.hasPrefix($0) || query.contains($0) }) {
            return true
        }
        return false
    }

    private static func currencyResult(for query: String, settings: ExteraInlineResultsSettings, rates: ExteraRatesSnapshot) -> (resultText: String, value: Double)? {
        guard hasRecognizedCurrencyToken(in: query) else {
            return nil
        }
        return ExteraCurrencyConverter.convert(query: query, defaultCurrency: settings.effectiveDefaultCurrency, rates: rates)
    }

    private static func hasRecognizedCurrencyToken(in query: String) -> Bool {
        let words = query.split(whereSeparator: { $0 == " " })
        for word in words {
            let cleaned = word.trimmingCharacters(in: CharacterSet(charactersIn: "$€£¥₽₴₺₹"))
            if !cleaned.isEmpty && cleaned != word {
                return true
            }
            if ExteraCurrencySupport.isValidIsoCode(cleaned) || ExteraCurrencySupport.currencyForSymbol(cleaned) != nil {
                return true
            }
            if ["stars", "star", "xtr"].contains(cleaned) {
                return true
            }
        }
        return false
    }

    private static func timeZoneResult(for query: String) -> String? {
        let words = query.split(whereSeparator: { $0 == " " }).map(String.init)

        if let match = ExteraTimezoneResolver.match(in: query) {
            if words.contains("now") || (words.count >= 2 && words[0] == "time") || (words.contains("in") && words.first == "now") {
                return ExteraTimezoneResolver.currentTimeString(match: match)
            }
            if words.contains(":") {
                return ExteraTimezoneResolver.convertedTimeString(from: query, match: match)
            }
        }
        if let hourMatch = words.first(where: { $0.contains(":") }), Int(hourMatch.split(separator: ":").first ?? "") != nil {
            let restWords = words.filter({ $0 != hourMatch })
            if let match = ExteraTimezoneResolver.match(in: restWords.joined(separator: " ")) {
                return ExteraTimezoneResolver.convertedTimeString(from: query, match: match)
            }
        }
        return nil
    }
}
