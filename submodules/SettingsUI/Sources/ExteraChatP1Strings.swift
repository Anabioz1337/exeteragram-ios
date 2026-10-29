import Foundation

private final class ExteraChatP1BundleAnchor: NSObject {}

private let exteraChatP1StringsBundle: Bundle = {
    let container = Bundle(for: ExteraChatP1BundleAnchor.self)
    guard let path = container.path(forResource: "ExteraChatP1UIBundle", ofType: "bundle"), let bundle = Bundle(path: path) else {
        return container
    }
    return bundle
}()

public func exteraChatP1String(_ key: String) -> String {
    return exteraChatP1StringsBundle.localizedString(forKey: key, value: key, table: nil)
}
