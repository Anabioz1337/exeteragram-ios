import Foundation

private final class ExteraStringsBundleReference: NSObject {
}

private final class ExteraStringsStore {
    static let shared = ExteraStringsStore()

    private let lock = NSLock()
    private var caches: [String: [String: String]] = [:]

    func values(for localization: String) -> [String: String] {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }

        if let cached = self.caches[localization] {
            return cached
        }

        var values: [String: String] = [:]
        if let bundlePath = Bundle(for: ExteraStringsBundleReference.self).path(forResource: "ExteraPreferencesUIBundle", ofType: "bundle"), let bundle = Bundle(path: bundlePath) {
            var lprojPath: String?
            if let localizationPath = bundle.path(forResource: localization, ofType: "lproj") {
                lprojPath = localizationPath
            } else {
                lprojPath = bundle.path(forResource: "en", ofType: "lproj")
            }
            if let lprojPath = lprojPath, let lprojBundle = Bundle(path: lprojPath), let stringsPath = lprojBundle.path(forResource: "ExteraStrings", ofType: "strings"), let dictionary = NSDictionary(contentsOfFile: stringsPath) as? [String: String] {
                values = dictionary
            }
        }

        self.caches[localization] = values
        return values
    }
}

public struct ExteraStrings {
    private let values: [String: String]

    public init(languageCode: String) {
        self.values = ExteraStringsStore.shared.values(for: languageCode.hasPrefix("ru") ? "ru" : "en")
    }

    public func value(_ key: String) -> String {
        (self.values[key] ?? key).replacingOccurrences(of: "**", with: "")
    }

    public func formatted(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: self.value(key), arguments: arguments)
    }
}
