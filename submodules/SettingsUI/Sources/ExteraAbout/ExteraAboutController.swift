import Foundation
import UIKit
import SwiftSignalKit
import Display
import TelegramPresentationData
import AccountContext
import ItemListUI
import ExteraBranding

private enum ExteraAboutSection: Int32 {
    case info
    case links
}

private final class ExteraAboutArguments {
    let openLink: (URL) -> Void
    let openAppIcons: () -> Void

    init(openLink: @escaping (URL) -> Void, openAppIcons: @escaping () -> Void) {
        self.openLink = openLink
        self.openAppIcons = openAppIcons
    }
}

private enum ExteraAboutEntry: ItemListNodeEntry {
    case description(String)
    case version(String, String)
    case copyright(String)
    case website(String)
    case sourceCode(String)
    case channel(String)
    case support(String)
    case appIcons(String)

    var section: ItemListSectionId {
        switch self {
        case .description, .version, .copyright:
            return ExteraAboutSection.info.rawValue
        case .website, .sourceCode, .channel, .support, .appIcons:
            return ExteraAboutSection.links.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .description: return 0
        case .version: return 1
        case .copyright: return 2
        case .website: return 3
        case .sourceCode: return 4
        case .channel: return 5
        case .support: return 6
        case .appIcons: return 7
        }
    }

    static func <(lhs: ExteraAboutEntry, rhs: ExteraAboutEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraAboutArguments
        switch self {
        case let .description(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .version(title, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {})
        case let .copyright(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .website(title):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openLink(ExteraBrandingLinks.website)
            })
        case let .sourceCode(title):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openLink(ExteraBrandingLinks.sourceCode)
            })
        case let .channel(title):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openLink(ExteraBrandingLinks.officialChannel)
            })
        case let .support(title):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openLink(ExteraBrandingLinks.support)
            })
        case let .appIcons(title):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openAppIcons()
            })
        }
    }
}

private func exteraAboutEntries(presentationData: PresentationData) -> [ExteraAboutEntry] {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    return [
        .description(exteraBrandingString("extera_About.Description")),
        .version(exteraBrandingString("extera_About.Version"), "\(version) (\(exteraBrandingVersionSuffix))"),
        .copyright(exteraBrandingString("extera_About.Copyright")),
        .website(exteraBrandingString("extera_About.Website")),
        .sourceCode(exteraBrandingString("extera_About.SourceCode")),
        .channel(exteraBrandingString("extera_About.Channel")),
        .support(exteraBrandingString("extera_About.Support")),
        .appIcons(exteraBrandingString("extera_About.AppIcons")),
    ]
}

public func exteraAboutController(context: AccountContext) -> ViewController {
    let pushControllerImpl = Atomic<(ViewController) -> Void>(value: { _ in })

    let arguments = ExteraAboutArguments(
        openLink: { url in
            context.sharedContext.applicationBindings.openUrl(url.absoluteString)
        },
        openAppIcons: {
            pushControllerImpl.with { impl in
                impl(themeSettingsController(context: context))
            }
        }
    )

    let signal = context.sharedContext.presentationData
    |> deliverOnMainQueue
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(exteraBrandingString("extera_About.Title")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraAboutEntries(presentationData: presentationData), style: .blocks)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal

    let _ = pushControllerImpl.swap({ [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    })
    return controller
}
