import Foundation

private final class ExteraAIBundleAnchor {
}

private let exteraAIStringsBundle: Bundle? = Bundle(for: ExteraAIBundleAnchor.self)
    .path(forResource: "ExteraAIBundle", ofType: "bundle")
    .flatMap { Bundle(path: $0) }

public func exteraAIString(_ key: String) -> String {
    return exteraAIStringsBundle?.localizedString(forKey: key, value: key, table: nil) ?? key
}
