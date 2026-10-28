import UIKit
import SwiftSignalKit

/// Placeholder settings screen for the extera translator. The real UI replaces
/// this; the rows cycle through the allowed values until then.
public final class ExteraTranslatorScreen: UITableViewController {
    private enum Row: Int, CaseIterable {
        case enabled
        case provider
        case targetLanguage
    }

    private let languages = exteraTranslationLanguages()
    private var preferencesDisposable: Disposable?

    private var preferences: ExteraTranslationPreferences

    public override init(style: UITableView.Style = .grouped) {
        self.preferences = ExteraTranslatorSettings.shared.current
        super.init(style: style)
        self.title = exteraTranslatorString("ExteraTranslator.ServiceTitle")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update(_ transform: (inout ExteraTranslationPreferences) -> ExteraTranslationPreferences) {
        var updated = self.preferences
        let next = transform(&updated)
        self.preferences = next
        ExteraTranslatorSettings.shared.update(next)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.preferencesDisposable = (ExteraTranslatorSettings.shared.preferencesSignal |> runOn(Queue.mainQueue()))
            .start(next: { [weak self] preferences in
                guard let self else {
                    return
                }
                self.preferences = preferences
                self.tableView.reloadData()
            })
    }

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Row.allCases.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        switch Row(rawValue: indexPath.row) ?? .enabled {
        case .enabled:
            let toggle = UISwitch()
            toggle.isOn = self.preferences.enabled
            toggle.addAction(UIAction { [weak self] action in
                if let senderSwitch = action.sender as? UISwitch {
                    self?.update({ preferences in
                        preferences.enabled = senderSwitch.isOn
                        return preferences
                    })
                }
            }, for: .valueChanged)
            cell.textLabel?.text = exteraTranslatorString("ExteraTranslator.Enabled")
            cell.selectionStyle = .none
            cell.accessoryView = toggle
        case .provider:
            cell.textLabel?.text = exteraTranslatorString("ExteraTranslator.Provider")
            cell.detailTextLabel?.text = exteraTranslatorString(self.preferences.provider == .google ? "ExteraTranslator.ProviderGoogle" : "ExteraTranslator.ProviderYandex")
            cell.accessoryType = .disclosureIndicator
        case .targetLanguage:
            cell.textLabel?.text = exteraTranslatorString("ExteraTranslator.TargetLanguage")
            if let targetLanguage = self.preferences.targetLanguage {
                cell.detailTextLabel?.text = targetLanguage.name
            } else {
                cell.detailTextLabel?.text = exteraTranslatorString("ExteraTranslator.FollowAppLanguage")
            }
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Row(rawValue: indexPath.row) ?? .enabled {
        case .enabled:
            break
        case .provider:
            self.update({ preferences in
                preferences.provider = preferences.provider == .google ? .yandex : .google
                return preferences
            })
        case .targetLanguage:
            let targets: [ExteraTranslationLanguage?] = [nil] + self.languages
            let currentIndex: Int
            if let current = self.preferences.targetLanguage, let index = targets.firstIndex(where: { $0?.code == current.code }) {
                currentIndex = index
            } else {
                currentIndex = 0
            }
            let next = targets[(currentIndex + 1) % targets.count]
            self.update({ preferences in
                preferences.targetLanguage = next
                return preferences
            })
        }
        self.tableView.reloadData()
    }
}
