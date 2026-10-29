import UIKit
import SwiftSignalKit

public final class ExteraPluginDeveloperScreen: UITableViewController {
    private enum Section: Int, CaseIterable {
        case server
        case reload
        case logs
    }

    private let store = ExteraPluginUIStore.shared
    private let maxVisibleLogRows = 50
    private var serverURL: String
    private var logs: [ExteraPluginLogEntry] = []
    private var stateDisposable: Disposable?

    public override init(style: UITableView.Style = .grouped) {
        self.serverURL = ExteraPluginUIStore.shared.developerServerURLValue
        super.init(style: style)
        self.title = exteraPluginsString("Extera.Plugins.DevMode.Title")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.stateDisposable?.dispose()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.keyboardDismissMode = .onDrag
        self.stateDisposable = (self.store.logs.get()
        |> deliverOnMainQueue).startStrict(next: { [weak self] logs in
            guard let self else {
                return
            }
            self.logs = logs
            self.tableView.reloadData()
        })
    }

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) ?? .server {
        case .server:
            return 1
        case .reload:
            return 1
        case .logs:
            return max(self.logs.count, 1)
        }
    }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) ?? .server {
        case .server:
            return exteraPluginsString("Extera.Plugins.DevMode.Title")
        case .reload:
            return nil
        case .logs:
            return exteraPluginsString("Extera.Plugins.DevMode.LogsHeader")
        }
    }

    private func visibleLogRow(at row: Int) -> ExteraPluginLogEntry? {
        let offset = max(self.logs.count - self.maxVisibleLogRows, 0)
        let index = offset + row
        guard index < self.logs.count else {
            return nil
        }
        return self.logs[index]
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) ?? .server {
        case .server:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = exteraPluginsString("Extera.Plugins.DevMode.ServerURL")
            let field = UITextField()
            field.placeholder = "https://127.0.0.1:9000"
            field.text = self.serverURL
            field.textAlignment = .right
            field.autoresizingMask = [.flexibleWidth]
            field.frame = CGRect(x: 0.0, y: 0.0, width: 160.0, height: 22.0)
            field.delegate = self
            field.addTarget(self, action: #selector(serverURLChanged(_:)), for: .editingChanged)
            cell.accessoryView = field
            cell.selectionStyle = .none
            return cell
        case .reload:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = exteraPluginsString("Extera.Plugins.DevMode.Reload")
            return cell
        case .logs:
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            guard let entry = self.visibleLogRow(at: indexPath.row) else {
                cell.textLabel?.text = exteraPluginsString("Extera.Plugins.DevMode.NoLogs")
                cell.textLabel?.textColor = .secondaryLabel
                cell.selectionStyle = .none
                return cell
            }
            cell.textLabel?.text = entry.text
            cell.detailTextLabel?.text = self.timeFormatter.string(from: entry.timestamp)
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.selectionStyle = .none
            return cell
        }
    }

    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    @objc private func serverURLChanged(_ sender: UITextField) {
        self.serverURL = sender.text ?? ""
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section) ?? .server {
        case .server:
            break
        case .reload:
            self.store.appendLog(exteraPluginsString("Extera.Plugins.DevMode.Reloaded"))
        case .logs:
            break
        }
    }
}

extension ExteraPluginDeveloperScreen: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.store.setDeveloperServerURL(self.serverURL)
    }
}
