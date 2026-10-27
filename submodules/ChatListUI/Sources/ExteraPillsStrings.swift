import Foundation
import UIKit

private final class ExteraPillsBundleAnchor: NSObject {
}

private let exteraPillsStringsBundle: Bundle? = Bundle(for: ExteraPillsBundleAnchor.self).path(forResource: "ExteraPillsBundle", ofType: "bundle").flatMap { Bundle(path: $0) }

/// Pill Stack / Inline Results strings, resolved from the module bundle with the
/// device's preferred localization (en and ru tables ship in it).
public func exteraPillString(_ key: String) -> String {
    let fallback = key.replacingOccurrences(of: "extera_", with: "")
    return exteraPillsStringsBundle?.localizedString(forKey: key, value: fallback, table: nil) ?? fallback
}
