import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import AccountContext
import TelegramStringFormatting
import TelegramUIPreferences
import exteraSettingsCore
import Postbox

public enum ExteraMessageDetailsDateFormat: Int32, CaseIterable {
    case none = 0
    case relative = 1
    case shortTime = 2
    case longTime = 3
    case shortDate = 4
    case longDate = 5
    case dayOfWeek = 6

    public func title(_ strings: PresentationStrings) -> String {
        switch self {
            case .none:
                return strings.extera_DateFormatOptionNone
            case .relative:
                return strings.extera_DateFormatOptionRelative
            case .shortTime:
                return strings.extera_DateFormatOptionShortTime
            case .longTime:
                return strings.extera_DateFormatOptionLongTime
            case .shortDate:
                return strings.extera_DateFormatOptionShortDate
            case .longDate:
                return strings.extera_DateFormatOptionLongDate
            case .dayOfWeek:
                return strings.extera_DateFormatOptionDayOfWeek
        }
    }
}

func exteraFormattedTimestamp(_ timestamp: Int32, format: ExteraMessageDetailsDateFormat) -> String {
    let date = Date(timeIntervalSince1970: Double(timestamp))
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    switch format {
        case .none:
            return ""
        case .relative:
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.locale = Locale.current
            return relativeFormatter.localizedString(for: date)
        case .shortTime:
            formatter.timeStyle = .short
        case .longTime:
            formatter.timeStyle = .medium
        case .shortDate:
            formatter.dateStyle = .short
        case .longDate:
            formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM y")
        case .dayOfWeek:
            formatter.setLocalizedDateFormatFromTemplate("EEEE")
    }
    return formatter.string(from: date)
}

private struct MessageMediaSummary: Equatable {
    var fileName: String?
    var fileSize: Int64?
    var mimeType: String?
    var durationSeconds: Double?
    var dimensions: PixelDimensions?
    var localFilePath: String?

    init(message: Message, context: AccountContext) {
        for media in message.effectiveMedia {
            if let file = media as? TelegramMediaFile {
                self.fileName = file.fileName
                self.mimeType = file.mimeType
                self.localFilePath = context.engine.resources.completedResourcePath(id: EngineMediaResource.Id(file.resource.id))

                for attribute in file.attributes {
                    switch attribute {
                        case let .Video(duration, size, _, _, _, _):
                            self.durationSeconds = duration
                            self.dimensions = size
                        case let .Audio(_, duration, _, _, _):
                            self.durationSeconds = Double(duration)
                        default:
                            break
                    }
                }

                if self.fileSize == nil {
                    self.fileSize = engineFileSize(self.localFilePath ?? "").map({ Int64($0) })
                }
                break
            } else if let image = media as? TelegramMediaImage, let largestRepresentation = largestImageRepresentation(image.representations) {
                self.dimensions = largestRepresentation.dimensions
                self.localFilePath = context.engine.resources.completedResourcePath(id: EngineMediaResource.Id(largestRepresentation.resource.id))
                self.fileSize = engineFileSize(self.localFilePath ?? "").map({ Int64($0) })
                break
            }
        }
    }

    var bitrateKbps: Int64? {
        guard let fileSize = self.fileSize, fileSize > 0 else {
            return nil
        }
        guard let durationSeconds = self.durationSeconds, durationSeconds > 0.5 else {
            return nil
        }
        return Int64((Double(fileSize) * 8.0 / durationSeconds / 1000.0).rounded())
    }
}

private func botApiPeerIdString(_ peerId: PeerId) -> String {
    let id = peerId.id.id._internalGetInt64Value()
    if peerId.namespace == Namespaces.Peer.CloudChannel {
        return "-100\(id)"
    } else if peerId.namespace == Namespaces.Peer.CloudGroup {
        return "-\(id)"
    } else if peerId.namespace == Namespaces.Peer.CloudUser {
        return "\(id)"
    } else {
        return "\(peerId.toInt64())"
    }
}

private struct InfoRow: Equatable {
    let title: String
    let value: String
}

private struct DetailsContent: Equatable {
    var dateRows: [InfoRow]
    var mediaRows: [InfoRow]
    var platformRow: InfoRow?
    var datacenterValue: String
    var currentFormatTitle: String
}

private func makeDateRows(message: Message, dateFormat: ExteraMessageDetailsDateFormat, strings: PresentationStrings) -> [InfoRow] {
    guard dateFormat != .none else {
        return []
    }
    var rows: [InfoRow] = [
        InfoRow(title: strings.extera_Date, value: exteraFormattedTimestamp(message.timestamp, format: dateFormat))
    ]
    if let editedDate = message.editedTime {
        rows.append(InfoRow(title: strings.extera_EditedDate, value: exteraFormattedTimestamp(editedDate, format: dateFormat)))
    }
    if let forwardInfo = message.forwardInfo {
        rows.append(InfoRow(title: strings.extera_ForwardedDate, value: exteraFormattedTimestamp(forwardInfo.date, format: dateFormat)))
    }
    return rows
}

private func makeMediaRows(summary: MessageMediaSummary, strings: PresentationStrings) -> [InfoRow] {
    var rows: [InfoRow] = []

    func append(_ title: String, _ value: String?) {
        guard let value = value, !value.isEmpty else {
            return
        }
        rows.append(InfoRow(title: title, value: value))
    }

    if let dimensions = summary.dimensions, dimensions.width > 0 && dimensions.height > 0 {
        append(strings.extera_Resolution, "\(dimensions.width)x\(dimensions.height)")
    }
    if let bitrateKbps = summary.bitrateKbps {
        append(strings.extera_Bitrate, "\(bitrateKbps) kbps")
    }
    if let durationSeconds = summary.durationSeconds, durationSeconds > 0.5 {
        append(strings.extera_Duration, stringForDuration(Int32(durationSeconds.rounded())))
    }
    if let fileSize = summary.fileSize, fileSize > 0 {
        append(strings.extera_FileSize, ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
    }
    append(strings.extera_FileName, summary.fileName)
    append(strings.extera_MimeType, summary.mimeType)
    append(strings.extera_FilePath, summary.localFilePath)

    return rows
}

private enum ExteraMessageDetailsSection: Int32 {
    case dates = 0
    case media = 1
    case general = 2
    case formatting = 3
}

private enum ExteraMessageDetailsEntry: ItemListNodeEntry, Equatable {
    case detail(PresentationTheme, InfoRow, Int32, Int32)
    case dateFormat(PresentationTheme, String, String)

    var section: ItemListSectionId {
        switch self {
            case let .detail(_, _, sectionId, _):
                return sectionId
            case .dateFormat:
                return ExteraMessageDetailsSection.formatting.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
            case let .detail(_, _, sectionId, index):
                return sectionId * 100 + index + 1
            case .dateFormat:
                return ExteraMessageDetailsSection.formatting.rawValue * 100 + 1
        }
    }

    static func <(lhs: ExteraMessageDetailsEntry, rhs: ExteraMessageDetailsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraMessageDetailsArguments
        switch self {
            case let .detail(_, row, sectionId, _):
                return ItemListTextWithLabelItem(presentationData: presentationData, label: row.title, text: row.value, enabledEntityTypes: [], multiline: true, sectionId: sectionId, action: nil)
            case let .dateFormat(_, title, currentFormatTitle):
                return ItemListDisclosureItem(presentationData: presentationData, title: title, label: currentFormatTitle, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                    arguments.chooseDateFormat?()
                })
        }
    }
}

private final class ExteraMessageDetailsArguments {
    var chooseDateFormat: (() -> Void)?

    init() {
        self.chooseDateFormat = nil
    }
}

public func exteraMessageDetailsController(context: AccountContext, message: Message) -> ViewController {
    let summary = MessageMediaSummary(message: message, context: context)
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""

    let datacenterValue = botApiPeerIdString(message.id.peerId)

    let arguments = ExteraMessageDetailsArguments()

    let settingsSignal = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraSettings])
    |> map { sharedData -> ExteraSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.exteraSettings]?.get(ExteraSettings.self) ?? ExteraSettings.defaultSettings
    }
    |> distinctUntilChanged

    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, settingsSignal)
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let dateFormat = ExteraMessageDetailsDateFormat(rawValue: settings.dateFormat) ?? .none

        let content = DetailsContent(
            dateRows: makeDateRows(message: message, dateFormat: dateFormat, strings: presentationData.strings),
            mediaRows: makeMediaRows(summary: summary, strings: presentationData.strings),
            platformRow: appVersion.isEmpty ? nil : InfoRow(title: presentationData.strings.extera_Platform, value: presentationData.strings.extera_SentFrom(appVersion).string),
            datacenterValue: datacenterValue,
            currentFormatTitle: dateFormat.title(presentationData.strings)
        )

        var entries: [ExteraMessageDetailsEntry] = []
        for (index, row) in content.dateRows.enumerated() {
            entries.append(.detail(presentationData.theme, row, ExteraMessageDetailsSection.dates.rawValue, Int32(index)))
        }
        for (index, row) in content.mediaRows.enumerated() {
            entries.append(.detail(presentationData.theme, row, ExteraMessageDetailsSection.media.rawValue, Int32(index)))
        }
        if let platformRow = content.platformRow {
            entries.append(.detail(presentationData.theme, platformRow, ExteraMessageDetailsSection.general.rawValue, 0))
        }
        entries.append(.detail(presentationData.theme, InfoRow(title: presentationData.strings.extera_Datacenter, value: content.datacenterValue), ExteraMessageDetailsSection.general.rawValue, 1))
        entries.append(.dateFormat(presentationData.theme, presentationData.strings.extera_DateFormatOption, content.currentFormatTitle))

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(presentationData.strings.extera_Details),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal, tabBarItem: nil)
    controller.navigationPresentation = .modal

    arguments.chooseDateFormat = { [weak controller] in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let actionSheet = ActionSheetController(presentationData: presentationData)
        actionSheet.setItemGroups([
            ActionSheetItemGroup(items: ExteraMessageDetailsDateFormat.allCases.filter { $0 != .none }.map { format in
                ActionSheetButtonItem(title: format.title(presentationData.strings), color: .accent, action: { [weak actionSheet] in
                    actionSheet?.dismissAnimated()
                    let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                        var updated = settings
                        updated.dateFormat = format.rawValue
                        return updated
                    }).startStandalone()
                })
            }),
            ActionSheetItemGroup(items: [
                ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                    actionSheet?.dismissAnimated()
                })
            ])
        ])
        controller?.present(actionSheet, in: .window(.root), with: ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
    }

    return controller
}
