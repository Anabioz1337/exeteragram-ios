import Foundation
import TelegramCore
import SwiftSignalKit

public enum ExteraWeatherLocationSource: Int32, Equatable {
    case current
    case manual
}

public struct ExteraWeatherLocation: Equatable {
    public let source: ExteraWeatherLocationSource
    public let latitude: Double
    public let longitude: Double
    public let title: String?

    public init(source: ExteraWeatherLocationSource, latitude: Double = 0.0, longitude: Double = 0.0, title: String? = nil) {
        self.source = source
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
    }

    public static func ==(lhs: ExteraWeatherLocation, rhs: ExteraWeatherLocation) -> Bool {
        return lhs.source == rhs.source && lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude && lhs.title == rhs.title
    }
}

public enum ExteraCryptoPillTargetCurrency: Int32, Equatable {
    case btc
    case eth
    case usd

    public var apiId: String {
        switch self {
        case .btc: return "bitcoin"
        case .eth: return "ethereum"
        case .usd: return "tether"
        }
    }
}

public enum ExteraPillKind: String, Equatable, CaseIterable {
    case unread
    case media
    case files
    case links
    case voice
    case weather
    case crypto
}

public struct ExteraPillStackSettings: Codable, Equatable {
    public let activePills: [String]
    public let hiddenPills: [String]
    public let infiniteScrolling: Bool
    public let weatherLocation: ExteraWeatherLocation?
    public let cryptoTargetCurrency: ExteraCryptoPillTargetCurrency

    public static var defaultSettings: ExteraPillStackSettings {
        return ExteraPillStackSettings(
            activePills: [ExteraPillKind.unread.rawValue, ExteraPillKind.media.rawValue, ExteraPillKind.files.rawValue, ExteraPillKind.links.rawValue, ExteraPillKind.voice.rawValue, ExteraPillKind.weather.rawValue, ExteraPillKind.crypto.rawValue],
            hiddenPills: [],
            infiniteScrolling: true,
            weatherLocation: nil,
            cryptoTargetCurrency: .usd
        )
    }

    public init(activePills: [String], hiddenPills: [String], infiniteScrolling: Bool, weatherLocation: ExteraWeatherLocation?, cryptoTargetCurrency: ExteraCryptoPillTargetCurrency) {
        self.activePills = activePills
        self.hiddenPills = hiddenPills
        self.infiniteScrolling = infiniteScrolling
        self.weatherLocation = weatherLocation
        self.cryptoTargetCurrency = cryptoTargetCurrency
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        self.activePills = (try container.decodeIfPresent([String].self, forKey: "activePills") ?? []).filter({ ExteraPillKind(rawValue: $0) != nil })
        self.hiddenPills = (try container.decodeIfPresent([String].self, forKey: "hiddenPills") ?? []).filter({ ExteraPillKind(rawValue: $0) != nil })
        self.infiniteScrolling = (try container.decode(Int32.self, forKey: "infiniteScrolling")) != 0
        if let hasLocation = try? container.decodeIfPresent(Int32.self, forKey: "weatherLocationHasValue"), hasLocation != 0 {
            let sourceRaw = try container.decodeIfPresent(Int32.self, forKey: "weatherLocationSource") ?? ExteraWeatherLocationSource.current.rawValue
            let latitude = try container.decodeIfPresent(Double.self, forKey: "weatherLatitude") ?? 0.0
            let longitude = try container.decodeIfPresent(Double.self, forKey: "weatherLongitude") ?? 0.0
            let title = try container.decodeIfPresent(String.self, forKey: "weatherTitle")
            self.weatherLocation = ExteraWeatherLocation(source: ExteraWeatherLocationSource(rawValue: sourceRaw) ?? .current, latitude: latitude, longitude: longitude, title: title)
        } else {
            self.weatherLocation = nil
        }
        self.cryptoTargetCurrency = ExteraCryptoPillTargetCurrency(rawValue: (try container.decode(Int32.self, forKey: "cryptoTargetCurrency"))) ?? .usd
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode(self.activePills, forKey: "activePills")
        try container.encode(self.hiddenPills, forKey: "hiddenPills")
        try container.encode((self.infiniteScrolling ? 1 : 0) as Int32, forKey: "infiniteScrolling")
        if let location = self.weatherLocation {
            try container.encode(1 as Int32, forKey: "weatherLocationHasValue")
            try container.encode(location.source.rawValue, forKey: "weatherLocationSource")
            try container.encode(location.latitude, forKey: "weatherLatitude")
            try container.encode(location.longitude, forKey: "weatherLongitude")
            try container.encode(location.title, forKey: "weatherTitle")
        } else {
            try container.encode(0 as Int32, forKey: "weatherLocationHasValue")
        }
        try container.encode(self.cryptoTargetCurrency.rawValue, forKey: "cryptoTargetCurrency")
    }

    public static func ==(lhs: ExteraPillStackSettings, rhs: ExteraPillStackSettings) -> Bool {
        return lhs.activePills == rhs.activePills && lhs.hiddenPills == rhs.hiddenPills && lhs.infiniteScrolling == rhs.infiniteScrolling && lhs.weatherLocation == rhs.weatherLocation && lhs.cryptoTargetCurrency == rhs.cryptoTargetCurrency
    }

    public func withUpdatedActivePills(_ activePills: [String]) -> ExteraPillStackSettings {
        return ExteraPillStackSettings(activePills: activePills, hiddenPills: self.hiddenPills, infiniteScrolling: self.infiniteScrolling, weatherLocation: self.weatherLocation, cryptoTargetCurrency: self.cryptoTargetCurrency)
    }

    public func withUpdatedHiddenPills(_ hiddenPills: [String]) -> ExteraPillStackSettings {
        return ExteraPillStackSettings(activePills: self.activePills, hiddenPills: hiddenPills, infiniteScrolling: self.infiniteScrolling, weatherLocation: self.weatherLocation, cryptoTargetCurrency: self.cryptoTargetCurrency)
    }

    public func withUpdatedInfiniteScrolling(_ infiniteScrolling: Bool) -> ExteraPillStackSettings {
        return ExteraPillStackSettings(activePills: self.activePills, hiddenPills: self.hiddenPills, infiniteScrolling: infiniteScrolling, weatherLocation: self.weatherLocation, cryptoTargetCurrency: self.cryptoTargetCurrency)
    }

    public func withUpdatedWeatherLocation(_ weatherLocation: ExteraWeatherLocation?) -> ExteraPillStackSettings {
        return ExteraPillStackSettings(activePills: self.activePills, hiddenPills: self.hiddenPills, infiniteScrolling: self.infiniteScrolling, weatherLocation: weatherLocation, cryptoTargetCurrency: self.cryptoTargetCurrency)
    }

    public func withUpdatedCryptoTargetCurrency(_ currency: ExteraCryptoPillTargetCurrency) -> ExteraPillStackSettings {
        return ExteraPillStackSettings(activePills: self.activePills, hiddenPills: self.hiddenPills, infiniteScrolling: self.infiniteScrolling, weatherLocation: self.weatherLocation, cryptoTargetCurrency: currency)
    }

    public func moving(_ kind: String, fromIndex: Int, toIndex: Int) -> ExteraPillStackSettings {
        var reordered = self.activePills
        guard fromIndex >= 0 && fromIndex < reordered.count else {
            return self
        }
        let item = reordered.remove(at: fromIndex)
        let clampedToIndex = max(0, min(toIndex, reordered.count))
        reordered.insert(item, at: clampedToIndex)
        return self.withUpdatedActivePills(reordered)
    }

    /// The pills the search field renders, in order: everything active that is not hidden.
    public var visiblePills: [String] {
        return self.activePills.filter({ !self.hiddenPills.contains($0) })
    }
}

public enum ExteraAngleUnit: Int32, Equatable {
    case degrees
    case radians
}

public enum ExteraMeasureSystem: Int32, Equatable {
    case metric
    case imperial
}

public struct ExteraInlineResultsSettings: Codable, Equatable {
    public let showResults: Bool
    public let calculatorEnabled: Bool
    public let currenciesEnabled: Bool
    public let unitsEnabled: Bool
    public let timeZonesEnabled: Bool
    public let defaultCurrency: String
    public let angleUnit: ExteraAngleUnit
    public let measureSystem: ExteraMeasureSystem
    public let digitGrouping: Bool

    public static var defaultSettings: ExteraInlineResultsSettings {
        return ExteraInlineResultsSettings(
            showResults: true,
            calculatorEnabled: true,
            currenciesEnabled: true,
            unitsEnabled: true,
            timeZonesEnabled: true,
            defaultCurrency: "",
            angleUnit: .degrees,
            measureSystem: .metric,
            digitGrouping: false
        )
    }

    public init(showResults: Bool, calculatorEnabled: Bool, currenciesEnabled: Bool, unitsEnabled: Bool, timeZonesEnabled: Bool, defaultCurrency: String, angleUnit: ExteraAngleUnit, measureSystem: ExteraMeasureSystem, digitGrouping: Bool) {
        self.showResults = showResults
        self.calculatorEnabled = calculatorEnabled
        self.currenciesEnabled = currenciesEnabled
        self.unitsEnabled = unitsEnabled
        self.timeZonesEnabled = timeZonesEnabled
        self.defaultCurrency = defaultCurrency
        self.angleUnit = angleUnit
        self.measureSystem = measureSystem
        self.digitGrouping = digitGrouping
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        self.showResults = (try container.decode(Int32.self, forKey: "showResults")) != 0
        self.calculatorEnabled = (try container.decode(Int32.self, forKey: "calculatorEnabled")) != 0
        self.currenciesEnabled = (try container.decode(Int32.self, forKey: "currenciesEnabled")) != 0
        self.unitsEnabled = (try container.decode(Int32.self, forKey: "unitsEnabled")) != 0
        self.timeZonesEnabled = (try container.decode(Int32.self, forKey: "timeZonesEnabled")) != 0
        self.defaultCurrency = try container.decode(String.self, forKey: "defaultCurrency")
        self.angleUnit = ExteraAngleUnit(rawValue: (try container.decode(Int32.self, forKey: "angleUnit"))) ?? .degrees
        self.measureSystem = ExteraMeasureSystem(rawValue: (try container.decode(Int32.self, forKey: "measureSystem"))) ?? .metric
        self.digitGrouping = (try container.decode(Int32.self, forKey: "digitGrouping")) != 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode((self.showResults ? 1 : 0) as Int32, forKey: "showResults")
        try container.encode((self.calculatorEnabled ? 1 : 0) as Int32, forKey: "calculatorEnabled")
        try container.encode((self.currenciesEnabled ? 1 : 0) as Int32, forKey: "currenciesEnabled")
        try container.encode((self.unitsEnabled ? 1 : 0) as Int32, forKey: "unitsEnabled")
        try container.encode((self.timeZonesEnabled ? 1 : 0) as Int32, forKey: "timeZonesEnabled")
        try container.encode(self.defaultCurrency, forKey: "defaultCurrency")
        try container.encode(self.angleUnit.rawValue, forKey: "angleUnit")
        try container.encode(self.measureSystem.rawValue, forKey: "measureSystem")
        try container.encode((self.digitGrouping ? 1 : 0) as Int32, forKey: "digitGrouping")
    }

    public static func ==(lhs: ExteraInlineResultsSettings, rhs: ExteraInlineResultsSettings) -> Bool {
        return lhs.showResults == rhs.showResults && lhs.calculatorEnabled == rhs.calculatorEnabled && lhs.currenciesEnabled == rhs.currenciesEnabled && lhs.unitsEnabled == rhs.unitsEnabled && lhs.timeZonesEnabled == rhs.timeZonesEnabled && lhs.defaultCurrency == rhs.defaultCurrency && lhs.angleUnit == rhs.angleUnit && lhs.measureSystem == rhs.measureSystem && lhs.digitGrouping == rhs.digitGrouping
    }

    public var effectiveDefaultCurrency: String {
        return !self.defaultCurrency.isEmpty ? self.defaultCurrency : ExteraCurrencySupport.currencyForCurrentLocale()
    }

    public func withUpdatedShowResults(_ showResults: Bool) -> ExteraInlineResultsSettings {
        return ExteraInlineResultsSettings(showResults: showResults, calculatorEnabled: self.calculatorEnabled, currenciesEnabled: self.currenciesEnabled, unitsEnabled: self.unitsEnabled, timeZonesEnabled: self.timeZonesEnabled, defaultCurrency: self.defaultCurrency, angleUnit: self.angleUnit, measureSystem: self.measureSystem, digitGrouping: self.digitGrouping)
    }

    public func withUpdatedCalculatorEnabled(_ enabled: Bool) -> ExteraInlineResultsSettings {
        return ExteraInlineResultsSettings(showResults: self.showResults, calculatorEnabled: enabled, currenciesEnabled: self.currenciesEnabled, unitsEnabled: self.unitsEnabled, timeZonesEnabled: self.timeZonesEnabled, defaultCurrency: self.defaultCurrency, angleUnit: self.angleUnit, measureSystem: self.measureSystem, digitGrouping: self.digitGrouping)
    }

    public func withUpdatedCurrenciesEnabled(_ enabled: Bool) -> ExteraInlineResultsSettings {
        return ExteraInlineResultsSettings(showResults: self.showResults, calculatorEnabled: self.calculatorEnabled, currenciesEnabled: enabled, unitsEnabled: self.unitsEnabled, timeZonesEnabled: self.timeZonesEnabled, defaultCurrency: self.defaultCurrency, angleUnit: self.angleUnit, measureSystem: self.measureSystem, digitGrouping: self.digitGrouping)
    }

    public func withUpdatedUnitsEnabled(_ enabled: Bool) -> ExteraInlineResultsSettings {
        return ExteraInlineResultsSettings(showResults: self.showResults, calculatorEnabled: self.calculatorEnabled, currenciesEnabled: self.currenciesEnabled, unitsEnabled: enabled, timeZonesEnabled: self.timeZonesEnabled, defaultCurrency: self.defaultCurrency, angleUnit: self.angleUnit, measureSystem: self.measureSystem, digitGrouping: self.digitGrouping)
    }

    public func withUpdatedTimeZonesEnabled(_ enabled: Bool) -> ExteraInlineResultsSettings {
        return ExteraInlineResultsSettings(showResults: self.showResults, calculatorEnabled: self.calculatorEnabled, currenciesEnabled: self.currenciesEnabled, unitsEnabled: self.unitsEnabled, timeZonesEnabled: enabled, defaultCurrency: self.defaultCurrency, angleUnit: self.angleUnit, measureSystem: self.measureSystem, digitGrouping: self.digitGrouping)
    }

    public func withUpdatedDefaultCurrency(_ currency: String) -> ExteraInlineResultsSettings {
        return ExteraInlineResultsSettings(showResults: self.showResults, calculatorEnabled: self.calculatorEnabled, currenciesEnabled: self.currenciesEnabled, unitsEnabled: self.unitsEnabled, timeZonesEnabled: self.timeZonesEnabled, defaultCurrency: currency, angleUnit: self.angleUnit, measureSystem: self.measureSystem, digitGrouping: self.digitGrouping)
    }

    public func withUpdatedAngleUnit(_ angleUnit: ExteraAngleUnit) -> ExteraInlineResultsSettings {
        return ExteraInlineResultsSettings(showResults: self.showResults, calculatorEnabled: self.calculatorEnabled, currenciesEnabled: self.currenciesEnabled, unitsEnabled: self.unitsEnabled, timeZonesEnabled: self.timeZonesEnabled, defaultCurrency: self.defaultCurrency, angleUnit: angleUnit, measureSystem: self.measureSystem, digitGrouping: self.digitGrouping)
    }

    public func withUpdatedMeasureSystem(_ system: ExteraMeasureSystem) -> ExteraInlineResultsSettings {
        return ExteraInlineResultsSettings(showResults: self.showResults, calculatorEnabled: self.calculatorEnabled, currenciesEnabled: self.currenciesEnabled, unitsEnabled: self.unitsEnabled, timeZonesEnabled: self.timeZonesEnabled, defaultCurrency: self.defaultCurrency, angleUnit: self.angleUnit, measureSystem: system, digitGrouping: self.digitGrouping)
    }

    public func withUpdatedDigitGrouping(_ digitGrouping: Bool) -> ExteraInlineResultsSettings {
        return ExteraInlineResultsSettings(showResults: self.showResults, calculatorEnabled: self.calculatorEnabled, currenciesEnabled: self.currenciesEnabled, unitsEnabled: self.unitsEnabled, timeZonesEnabled: self.timeZonesEnabled, defaultCurrency: self.defaultCurrency, angleUnit: self.angleUnit, measureSystem: self.measureSystem, digitGrouping: digitGrouping)
    }
}

public func updateExteraPillStackSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ExteraPillStackSettings) -> ExteraPillStackSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.exteraPillStackSettings, { entry in
            let currentSettings: ExteraPillStackSettings
            if let entry = entry?.get(ExteraPillStackSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = ExteraPillStackSettings.defaultSettings
            }
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}

public func updateExteraInlineResultsSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ExteraInlineResultsSettings) -> ExteraInlineResultsSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.exteraInlineResultsSettings, { entry in
            let currentSettings: ExteraInlineResultsSettings
            if let entry = entry?.get(ExteraInlineResultsSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = ExteraInlineResultsSettings.defaultSettings
            }
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}
