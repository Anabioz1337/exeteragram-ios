import Foundation
import Speech

public struct ExteraSpeechLocaleOption: Equatable {
    public let identifier: String
    public let displayName: String
}

private struct OnDeviceLocaleFamily {
    let primaryCode: String
    let identifiers: [String]
}

private let onDeviceLocaleFamilies: [OnDeviceLocaleFamily] = [
    OnDeviceLocaleFamily(primaryCode: "ar", identifiers: ["ar-SA"]),
    OnDeviceLocaleFamily(primaryCode: "cs", identifiers: ["cs-CZ"]),
    OnDeviceLocaleFamily(primaryCode: "da", identifiers: ["da-DK"]),
    OnDeviceLocaleFamily(primaryCode: "de", identifiers: ["de-DE", "de-AT", "de-CH"]),
    OnDeviceLocaleFamily(primaryCode: "el", identifiers: ["el-GR"]),
    OnDeviceLocaleFamily(primaryCode: "en", identifiers: ["en-US", "en-GB", "en-AU", "en-IN", "en-CA", "en-SG"]),
    OnDeviceLocaleFamily(primaryCode: "es", identifiers: ["es-ES", "es-MX", "es-US", "es-CL", "es-CO"]),
    OnDeviceLocaleFamily(primaryCode: "fi", identifiers: ["fi-FI"]),
    OnDeviceLocaleFamily(primaryCode: "fr", identifiers: ["fr-FR", "fr-CA", "fr-BE", "fr-CH"]),
    OnDeviceLocaleFamily(primaryCode: "he", identifiers: ["he-IL"]),
    OnDeviceLocaleFamily(primaryCode: "hi", identifiers: ["hi-IN"]),
    OnDeviceLocaleFamily(primaryCode: "hr", identifiers: ["hr-HR"]),
    OnDeviceLocaleFamily(primaryCode: "hu", identifiers: ["hu-HU"]),
    OnDeviceLocaleFamily(primaryCode: "id", identifiers: ["id-ID"]),
    OnDeviceLocaleFamily(primaryCode: "it", identifiers: ["it-IT"]),
    OnDeviceLocaleFamily(primaryCode: "ja", identifiers: ["ja-JP"]),
    OnDeviceLocaleFamily(primaryCode: "ko", identifiers: ["ko-KR"]),
    OnDeviceLocaleFamily(primaryCode: "ms", identifiers: ["ms-MY"]),
    OnDeviceLocaleFamily(primaryCode: "nb", identifiers: ["nb-NO"]),
    OnDeviceLocaleFamily(primaryCode: "nl", identifiers: ["nl-NL", "nl-BE"]),
    OnDeviceLocaleFamily(primaryCode: "pl", identifiers: ["pl-PL"]),
    OnDeviceLocaleFamily(primaryCode: "pt", identifiers: ["pt-BR", "pt-PT"]),
    OnDeviceLocaleFamily(primaryCode: "ro", identifiers: ["ro-RO"]),
    OnDeviceLocaleFamily(primaryCode: "ru", identifiers: ["ru-RU"]),
    OnDeviceLocaleFamily(primaryCode: "sk", identifiers: ["sk-SK"]),
    OnDeviceLocaleFamily(primaryCode: "sv", identifiers: ["sv-SE"]),
    OnDeviceLocaleFamily(primaryCode: "th", identifiers: ["th-TH"]),
    OnDeviceLocaleFamily(primaryCode: "tr", identifiers: ["tr-TR"]),
    OnDeviceLocaleFamily(primaryCode: "uk", identifiers: ["uk-UA"]),
    OnDeviceLocaleFamily(primaryCode: "vi", identifiers: ["vi-VN"]),
    OnDeviceLocaleFamily(primaryCode: "zh", identifiers: ["zh-CN", "zh-TW", "zh-HK"])
]

public let exteraSpeechAutoLanguageIdentifier = "auto"
public let exteraSpeechFallbackLanguageIdentifier = "en-US"

private func devicePrimaryLanguageCode(_ deviceLanguageCode: String) -> String {
    if deviceLanguageCode.contains("-") {
        return (deviceLanguageCode.split(separator: "-").first.map(String.init) ?? deviceLanguageCode).lowercased()
    }
    return deviceLanguageCode.lowercased()
}

func localeDisplayName(for identifier: String) -> String {
    let displayLanguageCode = Locale.current.localizedString(forIdentifier: identifier)
    if let displayLanguageCode, !displayLanguageCode.isEmpty {
        return displayLanguageCode
    }
    let regionName = Locale.current.localizedString(forRegionCode: String(identifier.suffix(2)))
    let languageName = Locale.current.localizedString(forLanguageCode: String(identifier.prefix(2)))
    if let languageName {
        if let regionName {
            return "\(languageName) (\(regionName))"
        }
        return languageName
    }
    return identifier
}

/// Recognition languages the system can serve fully offline, intersected with what
/// this OS build actually offers through `SFSpeechRecognizer`.
///
/// A curated family list is required rather than a filter over `supportedLocales()` alone:
/// that set contains server-only locales whose transcription would silently leave the
/// device. The catalog stays honest by construction, and the OS intersection keeps it
/// from listing anything this build cannot run at all.
public func exteraAvailableSpeechRecognitionLocales() -> [ExteraSpeechLocaleOption] {
    var supportedIdentifiers = Set<String>()
    for supported in SFSpeechRecognizer.supportedLocales() {
        supportedIdentifiers.insert(supported.identifier)
    }

    var result: [ExteraSpeechLocaleOption] = []
    for family in onDeviceLocaleFamilies {
        for identifier in family.identifiers where supportedIdentifiers.contains(identifier) {
            result.append(ExteraSpeechLocaleOption(identifier: identifier, displayName: localeDisplayName(for: identifier)))
        }
    }
    result.sort { lhs, rhs in
        if lhs.displayName.caseInsensitiveCompare(rhs.displayName) == .orderedSame {
            return lhs.identifier < rhs.identifier
        }
        return lhs.displayName.compare(rhs.displayName, options: [.caseInsensitive]) == .orderedAscending
    }
    return result
}

/// Maps `languageIdentifier` from settings (`auto` or a concrete BCP-47 id) to an
/// identifier the recognizer can actually run, preferring the device's own region.
public func resolveSpeechLocaleIdentifier(languageIdentifier: String, deviceLanguageCode: String) -> String {
    let available = exteraAvailableSpeechRecognitionLocales()

    if languageIdentifier != exteraSpeechAutoLanguageIdentifier {
        if available.contains(where: { $0.identifier == languageIdentifier }) {
            return languageIdentifier
        }
        let primary = devicePrimaryLanguageCode(languageIdentifier)
        if let match = available.first(where: { $0.identifier.hasPrefix("\(primary)-") }) {
            return match.identifier
        }
    } else {
        let primary = devicePrimaryLanguageCode(deviceLanguageCode)
        for family in onDeviceLocaleFamilies where family.primaryCode == primary {
            for identifier in family.identifiers where available.contains(where: { $0.identifier == identifier }) {
                return identifier
            }
        }
    }

    return exteraSpeechFallbackLanguageIdentifier
}
