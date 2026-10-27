import Foundation

// TODO(merge): delete this preview data together with the Install-from-File hook in
// ExteraPluginsScreen — the engine drives the report + consent chain through the store instead.
func exteraPluginUIInstallPreview() -> (descriptor: ExteraPluginUIDescriptor, report: ExteraAnalyzerReport) {
    let descriptor = ExteraPluginUIDescriptor(
        id: "sample.preview",
        name: "Sample Plugin",
        version: "1.0.0",
        author: "exteraGram",
        source: .unknown,
        criticalPermissions: [.giftUpgrade, .chatManagement],
        enabled: true,
        safeModeTriggered: false
    )
    let report = ExteraAnalyzerReport(
        pluginName: descriptor.name,
        source: .unknown,
        findings: [
            ExteraAnalyzerFinding(category: "Messages", level: .critical, notes: [
                "Deletes and rewrites messages in any chat"
            ]),
            ExteraAnalyzerFinding(category: "Network", level: .dangerous, notes: [
                "Opens arbitrary network connections",
                "Sends message metadata to a third-party server"
            ]),
            ExteraAnalyzerFinding(category: "Files", level: .caution, notes: [
                "Reads files from the documents directory"
            ])
        ],
        blocking: false
    )
    return (descriptor, report)
}
