import Foundation
import TelegramPresentationData

private final class ExteraAIBundleAnchor {
}

private let exteraAIStringsBundle: Bundle? = Bundle(for: ExteraAIBundleAnchor.self)
    .path(forResource: "ExteraAIBundle", ofType: "bundle")
    .flatMap { Bundle(path: $0) }

private func exteraAILookupString(_ key: String) -> String {
    return exteraAIStringsBundle?.localizedString(forKey: key, value: key, table: nil) ?? key
}

public func exteraAIString(_ key: String) -> String {
    return exteraAILookupString(key)
}

extension PresentationData {
    public func exteraAIString(_ key: String) -> String {
        return exteraAILookupString(key)
    }
}
