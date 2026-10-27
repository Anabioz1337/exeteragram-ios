import UIKit

/// TODO(merge): the engine invokes this from its sensitive-operation hook path. The bridge
/// (plugin -> UI request) is the part that still has to be wired on top of ExteraPluginCore.
public func exteraPluginUIPresentSensitiveRequestConfirmation(
    _ request: ExteraSensitiveRequest,
    presenting source: UIViewController,
    onConfirm: (() -> Void)? = nil,
    onDecline: (() -> Void)? = nil
) {
    let message = String(
        format: exteraPluginsString("Extera.Plugins.Sensitive.Message"),
        request.pluginName,
        request.permission.title
    )
    let alert = UIAlertController(
        title: exteraPluginsString("Extera.Plugins.Sensitive.Title"),
        message: message + "\n\n" + exteraPluginsString("Extera.Plugins.Sensitive.Footer"),
        preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: exteraPluginsString("Extera.Plugins.Sensitive.Confirm"), style: .default) { _ in
        ExteraPluginUIStore.shared.appendLog("Sensitive request confirmed: \(request.pluginId) · \(request.permission.rawValue)")
        onConfirm?()
    })
    alert.addAction(UIAlertAction(title: exteraPluginsString("Extera.Plugins.Sensitive.Decline"), style: .cancel) { _ in
        ExteraPluginUIStore.shared.appendLog("Sensitive request declined: \(request.pluginId) · \(request.permission.rawValue) · \(request.permission.title)")
        onDecline?()
    })
    source.present(alert, animated: true)
}
