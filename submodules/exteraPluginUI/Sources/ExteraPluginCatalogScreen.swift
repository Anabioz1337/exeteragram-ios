import UIKit
import SwiftSignalKit

// TODO(merge): placeholder catalog surface. Real entries come from t.me/exteraPluginRepo
// parsing (catalog channels) and the api.exteragram.app listing once the engine lands.
func exteraPluginUICatalogPreviewEntries() -> [ExteraCatalogEntry] {
    return [
        ExteraCatalogEntry(name: "Message Translator", version: "2.1.0", author: "exteraGram", isNew: true, isVerified: true),
        ExteraCatalogEntry(name: "Gift Manager", version: "0.9.4", author: "community", isNew: true, isVerified: false),
        ExteraCatalogEntry(name: "Auto Reply", version: "1.4.2", author: "community", isNew: false, isVerified: true)
    ]
}

public final class ExteraPluginCatalogScreen: UITableViewController {
    private enum Section: Int, CaseIterable {
        case repository
        case sorting
        case entries
    }

    private let store = ExteraPluginUIStore.shared
    private let previewEntries = exteraPluginUICatalogPreviewEntries()
    private var verifiedOnly: Bool
    private var selectedSorting: ExteraCatalogSorting
    private var stateDisposable: Disposable?

    public override init(style: UITableView.Style = .grouped) {
        self.verifiedOnly = ExteraPluginUIStore.shared.verifiedSourcesOnlyValue
        self.selectedSorting = ExteraPluginUIStore.shared.sortingValue
        super.init(style: style)
        self.title = exteraPluginsString("Extera.Plugins.Catalog")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.stateDisposable?.dispose()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.stateDisposable = (combineLatest(
            self.store.verifiedSourcesOnly.get(),
            self.store.sorting.get()
        )
        |> deliverOnMainQueue).startStrict(next: { [weak self] verifiedOnly, sorting in
            guard let self else {
                return
            }
            self.verifiedOnly = verifiedOnly
            self.selectedSorting = sorting
            self.tableView.reloadData()
        })
    }

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) ?? .repository {
        case .repository:
            return 2
        case .sorting:
            return ExteraCatalogSorting.allCases.count
        case .entries:
            return self.visibleEntries.count
        }
    }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) ?? .repository {
        case .repository:
            return exteraPluginsString("Extera.Plugins.Catalog.RepositoryHeader")
        case .sorting:
            return exteraPluginsString("Extera.Plugins.Catalog.SortingHeader")
        case .entries:
            return nil
        }
    }

    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(rawValue: section) == .repository else {
            return nil
        }
        return exteraPluginsString("Extera.Plugins.Catalog.VerifiedOnlyFooter")
    }

    private var visibleEntries: [ExteraCatalogEntry] {
        return self.previewEntries.filter { entry in
            !self.verifiedOnly || entry.isVerified
        }
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) ?? .repository {
        case .repository:
            return self.makeRepositoryCell(row: indexPath.row)
        case .sorting:
            let sorting = ExteraCatalogSorting.allCases[indexPath.row]
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = sorting.title
            cell.accessoryType = sorting == self.selectedSorting ? .checkmark : .none
            return cell
        case .entries:
            return self.makeEntryCell(index: indexPath.row)
        }
    }

    private func makeRepositoryCell(row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        if row == 0 {
            cell.textLabel?.text = exteraPluginsString("Extera.Plugins.Catalog.Channel")
            cell.detailTextLabel?.text = exteraPluginsString("Extera.Plugins.Catalog.ChannelValue")
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.textLabel?.text = exteraPluginsString("Extera.Plugins.Catalog.VerifiedOnly")
            cell.selectionStyle = .none
            let toggle = UISwitch()
            toggle.isOn = self.verifiedOnly
            toggle.addAction(UIAction { [weak self] action in
                guard let senderSwitch = action.sender as? UISwitch, let self else {
                    return
                }
                self.store.setVerifiedSourcesOnly(senderSwitch.isOn)
            }, for: .valueChanged)
            cell.accessoryView = toggle
        }
        return cell
    }

    private func makeEntryCell(index: Int) -> UITableViewCell {
        let entry = self.visibleEntries[index]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = entry.name
        let author = String(format: exteraPluginsString("Extera.Plugins.Author"), entry.author)
        let sourceLabel = exteraPluginsString(entry.isVerified ? "Extera.Plugins.Catalog.Verified" : "Extera.Plugins.Catalog.Unverified")
        cell.detailTextLabel?.text = "v\(entry.version) · \(author) · \(sourceLabel)"
        if entry.isNew {
            cell.detailTextLabel?.text = "\(exteraPluginsString("Extera.Plugins.Catalog.NewBadge")) · \(cell.detailTextLabel?.text ?? "")"
        }
        cell.detailTextLabel?.textColor = entry.isVerified ? .secondaryLabel : .systemOrange
        cell.selectionStyle = .none
        return cell
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section) ?? .repository {
        case .repository:
            if indexPath.row == 0, let url = URL(string: "https://t.me/exteraPluginRepo") {
                UIApplication.shared.open(url)
            }
        case .sorting:
            self.store.setSorting(ExteraCatalogSorting.allCases[indexPath.row])
        case .entries:
            break
        }
    }
}
