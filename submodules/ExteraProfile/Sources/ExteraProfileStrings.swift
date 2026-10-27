import Foundation
import UIKit

private final class ExteraProfileBundleAnchor: NSObject {
}

private let stringsBundle: Bundle? = Bundle(for: ExteraProfileBundleAnchor.self).path(forResource: "ExteraProfileBundle", ofType: "bundle").flatMap { Bundle(path: $0) }

public func exteraProfileString(_ key: String) -> String {
    return stringsBundle?.localizedString(forKey: key, value: key, table: nil) ?? key
}
