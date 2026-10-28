import Foundation

public struct ExteraTranslationLanguage: Equatable, Codable {
    public let name: String
    public let code: String

    public init(name: String, code: String) {
        self.name = name
        self.code = code
    }
}

/// Target language of the extera translator. `.followApp` tracks the interface
/// language of the running application; `.fixed` pins one of `allLanguages`.
public enum ExteraTranslationTarget: Equatable {
    case followApp
    case fixed(ExteraTranslationLanguage)
}

private let allLanguageValues = [
    "Arabic (AR)", "Azerbaijani (AZ)", "Belarusian (BE)", "Chinese (ZH)", "Croatian (HR)",
    "Czech (CS)", "Dutch (NL)", "English (EN)", "Estonian (ET)", "Finnish (FI)", "French (FR)",
    "German (DE)", "Greek (EL)", "Hungarian (HU)", "Indonesian (ID)", "Italian (IT)",
    "Japanese (JA)", "Korean (KO)", "Latvian (LV)", "Lithuanian (LT)", "Malay (MS)",
    "Norwegian (NO)", "Persian (FA)", "Polish (PL)", "Portuguese (PT)", "Romanian (RO)",
    "Russian (RU)", "Serbian (SR)", "Slovak (SK)", "Spanish (ES)", "Swedish (SV)",
    "Turkish (TR)", "Ukrainian (UK)", "Uzbek (UZ)"
]

/// Mirrors `ExteraConfig.supportedLanguages` from the Android fork, preserving
/// the "Name (CODE)" parsing and the default target (English).
public func exteraTranslationLanguages() -> [ExteraTranslationLanguage] {
    return allLanguageValues.compactMap { rawValue -> ExteraTranslationLanguage? in
        guard let openIndex = rawValue.firstIndex(of: "("), let closeIndex = rawValue.firstIndex(of: ")") else {
            return nil
        }
        let name = String(rawValue[..<openIndex]).trimmingCharacters(in: .whitespaces)
        let code = String(rawValue[rawValue.index(after: openIndex) ..< closeIndex])
        return ExteraTranslationLanguage(name: name, code: code)
    }
}
