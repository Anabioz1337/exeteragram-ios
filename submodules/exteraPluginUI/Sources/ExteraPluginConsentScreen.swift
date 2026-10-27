import UIKit
import SwiftSignalKit

public final class ExteraPluginConsentScreen: UITableViewController {
    private let descriptor: ExteraPluginUIDescriptor
    private let onConfirm: (() -> Void)?

    public init(descriptor: ExteraPluginUIDescriptor, onConfirm: (() -> Void)?) {
        self.descriptor = descriptor
        self.onConfirm = onConfirm
        super.init(style: .grouped)
        self.title = exteraPluginsString("Extera.Plugins.Consent.Title")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return self.descriptor.criticalPermissions.count
        default:
            return 2
        }
    }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return self.descriptor.name
        case 1:
            return exteraPluginsString("Extera.Plugins.Consent.Title")
        default:
            return nil
        }
    }

    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == 1 else {
            return nil
        }
        return exteraPluginsString("Extera.Plugins.Consent.Intro")
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = self.descriptor.name
            let sourceLabel = exteraPluginsString(self.descriptor.source == .verified ? "Extera.Plugins.Catalog.Verified" : "Extera.Plugins.Catalog.Unverified")
            cell.detailTextLabel?.text = sourceLabel
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.selectionStyle = .none
            return cell
        case 1:
            let permission = self.descriptor.criticalPermissions[indexPath.row]
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = permission.title
            cell.detailTextLabel?.text = permission.explanation
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.selectionStyle = .none
            return cell
        default:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = exteraPluginsString("Extera.Plugins.Consent.Confirm")
                cell.textLabel?.textColor = view.tintColor
            default:
                cell.textLabel?.text = exteraPluginsString("Extera.Plugins.Consent.Decline")
                cell.textLabel?.textColor = .systemRed
            }
            return cell
        }
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 2 else {
            return
        }
        if indexPath.row == 0, let onConfirm {
            onConfirm()
        } else {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}
