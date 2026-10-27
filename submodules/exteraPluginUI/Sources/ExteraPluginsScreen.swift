import UIKit
import SwiftSignalKit

public final class ExteraPluginsScreen: UITableViewController {
    private enum Section: Int, CaseIterable {
        case actions
        case plugins
    }

    private enum ActionRow: Int, CaseIterable {
        case catalog
        case installFromFile
    }

    private let store = ExteraPluginUIStore.shared
    private var plugins: [ExteraPluginUIDescriptor] = []
    private var pluginsDisposable: Disposable?

    public override init(style: UITableView.Style = .grouped) {
        super.init(style: style)
        self.title = exteraPluginsString("Extera.Plugins.Title")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.pluginsDisposable?.dispose()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.plugins = self.store.installedPluginsValue
        self.pluginsDisposable = (self.store.installedPlugins.get() |> deliverOnMainQueue).start(next: { [weak self] plugins in
            guard let self else {
                return
            }
            self.plugins = plugins
            self.tableView.reloadData()
        })
    }

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) ?? .actions {
        case .actions:
            return ActionRow.allCases.count
        case .plugins:
            return max(self.plugins.count, 1)
        }
    }

    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(rawValue: section) == .plugins, self.plugins.isEmpty else {
            return nil
        }
        return exteraPluginsString("Extera.Plugins.EmptyState.Text")
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) ?? .actions {
        case .actions:
            return self.makeActionCell(row: ActionRow(rawValue: indexPath.row) ?? .catalog)
        case .plugins:
            if self.plugins.isEmpty {
                return self.makeEmptyStateCell()
            }
            return self.makePluginCell(index: indexPath.row)
        }
    }

    private func makeActionCell(row: ActionRow) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        switch row {
        case .catalog:
            cell.textLabel?.text = exteraPluginsString("Extera.Plugins.Catalog")
        case .installFromFile:
            cell.textLabel?.text = exteraPluginsString("Extera.Plugins.InstallFromFile")
        }
        return cell
    }

    private func makeEmptyStateCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = exteraPluginsString("Extera.Plugins.EmptyState.Title")
        cell.textLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.text = exteraPluginsString("Extera.Plugins.EmptyState.Text")
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.selectionStyle = .none
        return cell
    }

    private func makePluginCell(index: Int) -> UITableViewCell {
        let plugin = self.plugins[index]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = plugin.name
        cell.detailTextLabel?.numberOfLines = 1
        let toggle = UISwitch()
        if plugin.safeModeTriggered {
            cell.detailTextLabel?.text = exteraPluginsString("Extera.Plugins.SafeModeBlocked") + " · v\(plugin.version)"
            cell.detailTextLabel?.textColor = .systemRed
            toggle.isOn = false
            toggle.isEnabled = false
        } else {
            let author = String(format: exteraPluginsString("Extera.Plugins.Author"), plugin.author)
            cell.detailTextLabel?.text = "\(author) · v\(plugin.version)"
            cell.detailTextLabel?.textColor = .secondaryLabel
            toggle.isOn = plugin.enabled
        }
        toggle.addAction(UIAction { [weak self] action in
            guard let senderSwitch = action.sender as? UISwitch, let self else {
                return
            }
            self.store.setEnabled(senderSwitch.isOn, pluginId: plugin.id)
        }, for: .valueChanged)
        cell.accessoryView = toggle
        cell.selectionStyle = .none
        return cell
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section) ?? .actions {
        case .actions:
            switch ActionRow(rawValue: indexPath.row) ?? .catalog {
            case .catalog:
                self.navigationController?.pushViewController(ExteraPluginCatalogScreen(), animated: true)
            case .installFromFile:
                self.beginInstallPreview()
            }
        case .plugins:
            break
        }
    }

    private func beginInstallPreview() {
        let preview = exteraPluginUIInstallPreview()
        self.navigationController?.pushViewController(ExteraPluginRiskReportScreen(report: preview.report, allowInstall: true, onInstall: {
            self.showConsent(for: preview.descriptor)
        }), animated: true)
    }

    private func showConsent(for descriptor: ExteraPluginUIDescriptor) {
        guard !descriptor.criticalPermissions.isEmpty else {
            self.store.add(descriptor)
            self.navigationController?.popToRootViewController(animated: true)
            return
        }
        self.navigationController?.pushViewController(ExteraPluginConsentScreen(descriptor: descriptor, onConfirm: {
            self.store.add(descriptor)
            self.navigationController?.popToRootViewController(animated: true)
        }), animated: true)
    }
}
