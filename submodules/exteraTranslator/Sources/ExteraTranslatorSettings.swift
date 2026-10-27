import Foundation
import SwiftSignalKit

public enum ExteraTranslationProvider: String, Codable, Equatable, CaseIterable {
    case google
    case yandex
}

public struct ExteraTranslationPreferences: Codable, Equatable {
    public var enabled: Bool
    public var provider: ExteraTranslationProvider
    /// `nil` means "follow the application language".
    public var targetLanguage: ExteraTranslationLanguage?

    public static let `default` = ExteraTranslationPreferences(enabled: false, provider: .google, targetLanguage: nil)

    public init(enabled: Bool, provider: ExteraTranslationProvider, targetLanguage: ExteraTranslationLanguage?) {
        self.enabled = enabled
        self.provider = provider
        self.targetLanguage = targetLanguage
    }
}

/// User defaults storage for the extera translator, kept in a dedicated
/// `exteraTranslator` defaults suite, with change notification through a signal.
public final class ExteraTranslatorSettings {
    public static let shared = ExteraTranslatorSettings()

    private static let defaults = UserDefaults(suiteName: "exteraTranslator") ?? .standard
    private static let preferencesKey = "preferences"

    private let promise = ValuePromise<ExteraTranslationPreferences>(ignoreRepeated: true)
    private let lock = NSLock()
    private var cachedPreferences: ExteraTranslationPreferences

    private init() {
        if let data = ExteraTranslatorSettings.defaults.data(forKey: ExteraTranslatorSettings.preferencesKey), let preferences = try? JSONDecoder().decode(ExteraTranslationPreferences.self, from: data) {
            self.cachedPreferences = preferences
        } else {
            self.cachedPreferences = .default
        }
    }

    public var current: ExteraTranslationPreferences {
        return self.lock.with {
            self.cachedPreferences
        }
    }

    /// Target language resolved against the app's interface language code.
    public func effectiveTargetLanguage(appLanguageCode: String?) -> String {
        let preferences = self.current
        if let targetLanguage = preferences.targetLanguage {
            return targetLanguage.code.lowercased()
        }
        let appLanguage = (appLanguageCode ?? "en").components(separatedBy: "-").first ?? appLanguageCode ?? "en"
        return appLanguage.lowercased()
    }

    public func update(_ preferences: ExteraTranslationPreferences) {
        let data = (try? JSONEncoder().encode(preferences)) ?? Data()
        ExteraTranslatorSettings.defaults.set(data, forKey: ExteraTranslatorSettings.preferencesKey)
        self.promise.set(preferences)
        self.lock.with {
            self.cachedPreferences = preferences
        }
    }

    public var preferencesSignal: Signal<ExteraTranslationPreferences, NoError> {
        return self.promise.signal()
    }
}

extension NSLock {
    fileprivate func with<T>(_ body: () -> T) -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return body()
    }
}
