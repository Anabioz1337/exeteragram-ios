import Foundation

final class ExteraCameraBundleAnchor: NSObject {
}

private let stringsBundle: Bundle? = Bundle(for: ExteraCameraBundleAnchor.self).path(forResource: "ExteraCameraBundle", ofType: "bundle").flatMap { Bundle(path: $0) }

public func exteraCameraString(_ key: String) -> String {
    return stringsBundle?.localizedString(forKey: key, value: key, table: nil) ?? key
}
