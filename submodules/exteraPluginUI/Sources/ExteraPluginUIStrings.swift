import Foundation

private final class ExteraPluginUIBundleAnchor: NSObject {}

private let exteraPluginUIStringsBundle: Bundle = {
    let container = Bundle(for: ExteraPluginUIBundleAnchor.self)
    guard let path = container.path(forResource: "ExteraPluginUIBundle", ofType: "bundle"), let bundle = Bundle(path: path) else {
        return container
    }
    return bundle
}()

public func exteraPluginsString(_ key: String) -> String {
    return exteraPluginUIStringsBundle.localizedString(forKey: key, value: key, table: nil)
}
