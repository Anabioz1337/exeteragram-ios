import Foundation
import UIKit

final class ExteraTranslatorBundleAnchor: NSObject {
}

private let stringsBundle: Bundle? = Bundle(for: ExteraTranslatorBundleAnchor.self).path(forResource: "ExteraTranslatorBundle", ofType: "bundle").flatMap { Bundle(path: $0) }

public func exteraTranslatorString(_ key: String) -> String {
    return stringsBundle?.localizedString(forKey: key, value: key, table: nil) ?? key
}
