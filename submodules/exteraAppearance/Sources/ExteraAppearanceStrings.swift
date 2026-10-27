import Foundation
import UIKit

final class ExteraAppearanceBundleAnchor: NSObject {
}

private let stringsBundle: Bundle? = Bundle(for: ExteraAppearanceBundleAnchor.self).path(forResource: "ExteraAppearanceBundle", ofType: "bundle").flatMap { Bundle(path: $0) }

public func exteraAppearanceString(_ key: String) -> String {
    return stringsBundle?.localizedString(forKey: key, value: key, table: nil) ?? key
}
