import Foundation
import SwiftSignalKit
import Display
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import AccountContext
import ItemListUI
import PresentationDataUtils

private enum ExteraPluginsSection: Int32 {
    case plugins
    case actions
}

private final class ExteraPluginsArguments {
    let togglePlugin: (String, Bool) -> Void
    let openPlugin: (InstalledExteraPlugin) -> Void
    let addPlugin: () -> Void

    init(togglePlugin: @escaping (String, Bool) -> Void, openPlugin: @escaping (InstalledExteraPlugin) -> Void, addPlugin: @escaping () -> Void) {
        self.togglePlugin = togglePlugin
        self.openPlugin = openPlugin
        self.addPlugin = addPlugin
    }
}

private enum ExteraPluginsEntry: ItemListNodeEntry {
    case header(String)
    case plugin(Int32, InstalledExteraPlugin)
    case empty(String)
    case actionsHeader(String)
    case addPlugin(String)

    var section: ItemListSectionId {
        switch self {
        case .header, .plugin, .empty:
            return ExteraPluginsSection.plugins.rawValue
        case .actionsHeader, .addPlugin:
            return ExteraPluginsSection.actions.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .header:
            return 0
        case let .plugin(index, _):
            return 10 + index
        case .empty:
            return 5
        case .actionsHeader:
            return 100
        case .addPlugin:
            return 101
        }
    }

    static func <(lhs: ExteraPluginsEntry, rhs: ExteraPluginsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraPluginsArguments
        switch self {
        case let .header(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .plugin(_, plugin):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "\(plugin.name) · v\(plugin.version)",
                value: plugin.enabled,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.togglePlugin(plugin.id, value)
                },
                action: {
                    arguments.openPlugin(plugin)
                }
            )
        case let .empty(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section, style: .blocks)
        case let .actionsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .addPlugin(title):
            return ItemListActionItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: { arguments.addPlugin() }
            )
        }
    }
}

public func exteraPluginsScreen(context: AccountContext) -> ViewController {
    let pushControllerImpl = Atomic<(ViewController) -> Void>(value: { _ in })

    let arguments = ExteraPluginsArguments(
        togglePlugin: { pluginId, enabled in
            let _ = updateExteraPluginsSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                return settings.withUpdatedEnabled(pluginId, enabled)
            }).startStandalone()
        },
        openPlugin: { [weak context] plugin in
            guard let context else {
                return
            }
            let editor = exteraPluginEditorScreen(context: context, existing: plugin)
            pushControllerImpl.with { impl in
                impl(editor)
            }
        },
        addPlugin: { [weak context] in
            guard let context else {
                return
            }
            let editor = exteraPluginEditorScreen(context: context, existing: nil)
            pushControllerImpl.with { impl in
                impl(editor)
            }
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        exteraPluginsSettings(accountManager: context.sharedContext.accountManager)
    )
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var entries: [ExteraPluginsEntry] = []
        entries.append(.header(presentationData.strings.Extera_Plugins_ListHeader))
        if settings.plugins.isEmpty {
            entries.append(.empty(presentationData.strings.Extera_Plugins_Empty))
        } else {
            for (index, plugin) in settings.plugins.enumerated() {
                entries.append(.plugin(Int32(clamping: index), plugin))
            }
        }
        entries.append(.actionsHeader(presentationData.strings.Extera_Plugins_ActionsHeader))
        entries.append(.addPlugin(presentationData.strings.Extera_Plugins_Add))

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(presentationData.strings.Extera_Plugins_Title),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal
    let _ = pushControllerImpl.swap({ [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    })
    return controller
}
