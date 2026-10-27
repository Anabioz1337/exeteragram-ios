import Foundation

public struct ExteraUnitConversionResult {
    public let value: Double
    public let fromUnitTitle: String
    public let toUnitTitle: String
    public let formatted: String
}

enum ExteraMeasureCategory {
    case length
    case weight
    case temperature
    case speed
    case volume
}

struct ExteraUnitDescription {
    let category: ExteraMeasureCategory
    let baseFactor: Double
    let isImperial: Bool
    let title: String
}

public enum ExteraUnitConverter {
    private static func lengthUnits() -> [String: ExteraUnitDescription] {
        var units: [String: ExteraUnitDescription] = [:]
        for entry in [
            (["m", "meter", "meters", "metre", "metres"], 1.0, false, "m"),
            (["cm"], 0.01, false, "cm"),
            (["mm"], 0.001, false, "mm"),
            (["km", "kilometer", "kilometers", "kilometre", "kilometres"], 1000.0, false, "km"),
            (["mi", "mile", "miles"], 1609.344, true, "mi"),
            (["ft", "feet", "foot"], 0.3048, true, "ft"),
            (["in", "inch", "inches"], 0.0254, true, "in"),
            (["yd", "yard", "yards"], 0.9144, true, "yd")
        ] as [(aliases: [String], factor: Double, imperial: Bool, title: String)] {
            for alias in entry.aliases {
                units[alias] = ExteraUnitDescription(category: .length, baseFactor: entry.factor, isImperial: entry.imperial, title: entry.title)
            }
        }
        return units
    }

    private static func weightUnits() -> [String: ExteraUnitDescription] {
        var units: [String: ExteraUnitDescription] = [:]
        for entry in [
            (["g", "gram", "grams"], 0.001, false, "g"),
            (["kg", "kilogram", "kilograms", "kilo", "kilos"], 1.0, false, "kg"),
            (["t", "tonne", "tonnes"], 1000.0, false, "t"),
            (["lb", "lbs", "pound", "pounds"], 0.45359237, true, "lb"),
            (["oz", "ounce", "ounces"], 0.45359237 / 16.0, true, "oz"),
            (["st", "stone", "stones"], 6.35029318, true, "st")
        ] as [(aliases: [String], factor: Double, imperial: Bool, title: String)] {
            for alias in entry.aliases {
                units[alias] = ExteraUnitDescription(category: .weight, baseFactor: entry.factor, isImperial: entry.imperial, title: entry.title)
            }
        }
        return units
    }

    private static func temperatureUnits() -> [String: ExteraUnitDescription] {
        var units: [String: ExteraUnitDescription] = [:]
        for entry in [
            (["c", "celsius", "centigrade", "\u{00B0}c"], false, "\u{00B0}C"),
            (["f", "fahrenheit", "\u{00B0}f"], true, "\u{00B0}F"),
            (["k", "kelvin"], false, "K")
        ] as [(aliases: [String], imperial: Bool, title: String)] {
            for alias in entry.aliases {
                units[alias] = ExteraUnitDescription(category: .temperature, baseFactor: 1.0, isImperial: entry.imperial, title: entry.title)
            }
        }
        return units
    }

    private static func speedUnits() -> [String: ExteraUnitDescription] {
        var units: [String: ExteraUnitDescription] = [:]
        for entry in [
            (["kmh", "kph", "km/h"], 1.0 / 3.6, false, "km/h"),
            (["mph", "mi/h"], 0.44704, true, "mph"),
            (["ms", "m/s"], 1.0, false, "m/s"),
            (["kn", "knot", "knots"], 0.514444, true, "kn")
        ] as [(aliases: [String], factor: Double, imperial: Bool, title: String)] {
            for alias in entry.aliases {
                units[alias] = ExteraUnitDescription(category: .speed, baseFactor: entry.factor, isImperial: entry.imperial, title: entry.title)
            }
        }
        return units
    }

    private static func volumeUnits() -> [String: ExteraUnitDescription] {
        var units: [String: ExteraUnitDescription] = [:]
        for entry in [
            (["l", "liter", "liters", "litre", "litres"], 1.0, false, "l"),
            (["ml"], 0.001, false, "ml"),
            (["gal", "gallon", "gallons"], 3.785411784, true, "gal"),
            (["qt", "quart", "quarts"], 0.946352946, true, "qt"),
            (["pt", "pint", "pints"], 0.473176473, true, "pt")
        ] as [(aliases: [String], factor: Double, imperial: Bool, title: String)] {
            for alias in entry.aliases {
                units[alias] = ExteraUnitDescription(category: .volume, baseFactor: entry.factor, isImperial: entry.imperial, title: entry.title)
            }
        }
        return units
    }

    private static let allUnits: [String: ExteraUnitDescription] = {
        var merged: [String: ExteraUnitDescription] = [:]
        for table in [lengthUnits(), weightUnits(), temperatureUnits(), speedUnits(), volumeUnits()] {
            for (name, description) in table {
                merged[name] = description
            }
        }
        return merged
    }()
    public static func convert(query: String, measureSystem: ExteraMeasureSystem) -> ExteraUnitConversionResult? {
        let words = query.lowercased()
            .replacingOccurrences(of: "\u{00B0}", with: "")
            .split(whereSeparator: { $0 == " " })
            .map(String.init)

        guard let amountWordIndex = words.firstIndex(where: { word -> Bool in
            return !word.isEmpty && Double(word.replacingOccurrences(of: ",", with: ".")) != nil
        }) else {
            return nil
        }
        guard let amount = Double(words[amountWordIndex].replacingOccurrences(of: ",", with: ".")) else {
            return nil
        }

        let followingWords = Array(words[(amountWordIndex + 1)...])
        let precedingWords = Array(words[..<amountWordIndex])

        guard let fromUnitName = firstKnownUnit(in: followingWords) ?? firstKnownUnit(in: precedingWords),
              let fromUnit = allUnits[fromUnitName] else {
            return nil
        }

        var separatorSeen = false
        var explicitTarget: String?
        for word in words {
            if word == "to" || word == "in" || word == "as" {
                if !separatorSeen {
                    separatorSeen = true
                } else {
                    break
                }
                continue
            }
            if separatorSeen, let known = allUnits[word], known.category == fromUnit.category, word != fromUnitName {
                explicitTarget = word
                break
            }
        }

        let resolvedTargetName: String?
        if let explicitTarget {
            resolvedTargetName = explicitTarget
        } else {
            let preferredIsImperial = measureSystem == .imperial
            let wantImperial = !fromUnit.isImperial == preferredIsImperial
            resolvedTargetName = counterpartTitle(for: fromUnit.title, imperial: wantImperial)
        }
        guard let targetName = resolvedTargetName, let targetUnit = allUnits[targetName] else {
            return nil
        }
        return makeResult(amount: amount, from: fromUnit, to: targetUnit)
    }

    private static func makeResult(amount: Double, from: ExteraUnitDescription, to: ExteraUnitDescription) -> ExteraUnitConversionResult {
        let convertedValue: Double
        if from.category == .temperature {
            convertedValue = convertedTemperature(amount, from: from.title, to: to.title)
        } else {
            convertedValue = amount * from.baseFactor / to.baseFactor
        }
        return ExteraUnitConversionResult(
            value: convertedValue,
            fromUnitTitle: from.title,
            toUnitTitle: to.title,
            formatted: "\(ExteraResultFormatter.format(convertedValue, groupDigits: false)) \(to.title)"
        )
    }

    private static let metricCounterparts: [String: String] = [
        "m": "ft", "km": "mi", "cm": "in", "mm": "in",
        "kg": "lb", "g": "oz", "t": "st",
        "\u{00B0}C": "\u{00B0}F", "K": "\u{00B0}C",
        "km/h": "mph", "m/s": "mph", "kn": "mph",
        "l": "gal", "ml": "pt"
    ]

    private static let imperialCounterparts: [String: String] = [
        "mi": "km", "ft": "m", "in": "cm", "yd": "m",
        "lb": "kg", "oz": "g", "st": "t",
        "\u{00B0}F": "\u{00B0}C",
        "mph": "km/h", "kn": "km/h",
        "gal": "l", "qt": "l", "pt": "ml"
    ]

    private static func counterpartTitle(for unitTitle: String, imperial: Bool) -> String? {
        return imperial ? imperialCounterparts[unitTitle] : metricCounterparts[unitTitle]
    }

    private static func convertedTemperature(_ amount: Double, from: String, to: String) -> Double {
        let celsius: Double
        switch from {
        case "\u{00B0}F":
            celsius = (amount - 32.0) * 5.0 / 9.0
        case "K":
            celsius = amount - 273.15
        default:
            celsius = amount
        }
        switch to {
        case "\u{00B0}F":
            return celsius * 9.0 / 5.0 + 32.0
        case "K":
            return celsius + 273.15
        default:
            return celsius
        }
    }

    private static func firstKnownUnit(in words: [String]) -> String? {
        for word in words where allUnits[word] != nil {
            return word
        }
        return nil
    }
}
