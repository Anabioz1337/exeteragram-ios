import UIKit
import SwiftSignalKit

public final class ExteraPluginRiskReportScreen: UITableViewController {
    private let report: ExteraAnalyzerReport
    private let allowInstall: Bool
    private let onInstall: (() -> Void)?

    public init(report: ExteraAnalyzerReport, allowInstall: Bool, onInstall: (() -> Void)?) {
        self.report = report
        self.allowInstall = allowInstall
        self.onInstall = onInstall
        super.init(style: .grouped)
        self.title = exteraPluginsString("Extera.Plugins.Report.Title")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func color(for level: ExteraAnalyzerSeverity) -> UIColor {
        switch level {
        case .critical:
            return .systemRed
        case .dangerous:
            return .systemOrange
        case .caution:
            return .systemYellow
        }
    }

    private func levelTitle(for level: ExteraAnalyzerSeverity) -> String {
        switch level {
        case .critical:
            return exteraPluginsString("Extera.Plugins.Report.Level.Critical")
        case .dangerous:
            return exteraPluginsString("Extera.Plugins.Report.Level.Dangerous")
        case .caution:
            return exteraPluginsString("Extera.Plugins.Report.Level.Caution")
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        if self.allowInstall, let onInstall {
            let action = UIAction { _ in
                onInstall()
            }
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: exteraPluginsString("Extera.Plugins.Consent.Confirm"),
                style: .done,
                primaryAction: action
            )
        }
    }

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return self.report.findings.count + 1
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        let finding = self.report.findings[section - 1]
        return max(finding.notes.count, 1)
    }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return exteraPluginsString("Extera.Plugins.Report.Header")
        }
        return self.report.findings[section - 1].category
    }

    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == 0 else {
            return nil
        }
        return exteraPluginsString("Extera.Plugins.Report.BlockingNote")
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = self.report.pluginName
            let sourceLabel = exteraPluginsString(self.report.source == .verified ? "Extera.Plugins.Catalog.Verified" : "Extera.Plugins.Catalog.Unverified")
            cell.detailTextLabel?.text = sourceLabel
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.selectionStyle = .none
            return cell
        }
        let finding = self.report.findings[indexPath.section - 1]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = self.levelTitle(for: finding.level)
        cell.textLabel?.textColor = self.color(for: finding.level)
        if finding.notes.isEmpty {
            cell.detailTextLabel?.text = nil
        } else {
            cell.detailTextLabel?.text = finding.notes[indexPath.row]
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.textColor = .secondaryLabel
        }
        cell.selectionStyle = .none
        return cell
    }
}
