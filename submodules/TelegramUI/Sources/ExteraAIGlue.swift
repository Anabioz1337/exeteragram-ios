import Foundation
import UIKit
import Display
import SwiftSignalKit
import AccountContext
import TelegramCore
import TelegramPresentationData
import UndoUI
import BrowserUI
import TextFormat
import exteraAICore
import ContextUI

private func exteraAIPresentResult(
    context: AccountContext,
    title: String,
    action: ExteraAIActionKind,
    sourceText: String,
    present: @escaping (ExteraAIResultController) -> Void,
    displayUndo: @escaping (UndoOverlayContent) -> Void,
    insertResult: @escaping (String, ExteraAIResponseDisplay) -> Void
) {
    guard case let .resolved(backend) = exteraAIResolveBackend() else {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        displayUndo(.info(title: presentationData.exteraAIString("Extera.AI.Title"), text: presentationData.exteraAIString("Extera.AI.ServicesInfo"), timeout: nil, customUndoText: nil))
        return
    }

    let store = ExteraAIStore.shared
    let settings = store.generationSettings
    let role = store.selectedRole

    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let resultController = ExteraAIResultController(theme: presentationData.theme, title: title)
    var generationTask: Task<Void>?

    resultController.onInsert = { result in
        insertResult(result, settings.responseDisplay)
        let updated = context.sharedContext.currentPresentationData.with { $0 }
        displayUndo(.succeed(text: updated.exteraAIString("Extera.AI.ResultInsertedToast"), timeout: nil, customUndoText: nil))
    }
    resultController.onCopy = { _ in
        let updated = context.sharedContext.currentPresentationData.with { $0 }
        displayUndo(.succeed(text: updated.exteraAIString("Extera.AI.ResultCopiedToast"), timeout: nil, customUndoText: nil))
    }
    resultController.onClose = {
        generationTask?.cancel()
    }

    present(resultController)

    generationTask = Task { @MainActor in
        do {
            var content = ""
            var reasoning = ""
            let result = try await exteraAIGenerate(backend: backend, settings: settings, role: role, action: action, input: sourceText) { event in
                switch event {
                case .content(let contentDelta):
                    content += contentDelta
                case .reasoning(let reasoningDelta):
                    reasoning += reasoningDelta
                }
                let currentContent = content
                let currentReasoning = reasoning
                Queue.mainQueue().async {
                    resultController.update(content: currentContent, reasoning: currentReasoning, isGenerating: true)
                }
            }
            Queue.mainQueue().async {
                resultController.update(content: result, reasoning: reasoning, isGenerating: false)
            }
        } catch let failure as ExteraAIGenerationFailure {
            let texts = exteraAIErrorTexts(failure: failure)
            Queue.mainQueue().async {
                resultController.fail(title: texts.title, info: texts.info)
            }
        } catch is CancellationError {
        } catch {
            Queue.mainQueue().async {
                resultController.fail(title: exteraAIString("Extera.AI.ErrorNetworkTitle"), info: exteraAIString("Extera.AI.ErrorNetworkInfo"))
            }
        }
    }
}

func exteraAIMessageContextMenuItems(
    context: AccountContext,
    message: EngineRawMessage,
    messageText: String,
    activeTranslateToLang: String?,
    controllerInteraction: ChatControllerInteraction?,
    interfaceInteraction: ChatPanelInterfaceInteraction?
) -> [ContextMenuItem] {
    guard case .resolved(_) = exteraAIResolveBackend(), !messageText.isEmpty else {
        return []
    }

    func item(text: String, iconName: String, actionKind: ExteraAIActionKind) -> ContextMenuItem {
        return .action(ContextMenuActionItem(text: text, icon: { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/\(iconName)"), color: theme.actionSheet.primaryTextColor)
        }, action: { _, f in
            f(.default)
            exteraAIPresentResult(
                context: context,
                title: text,
                action: actionKind,
                sourceText: messageText,
                present: { resultController in
                    controllerInteraction?.presentControllerInCurrent(resultController, nil)
                },
                displayUndo: { content in
                    controllerInteraction?.displayUndo(content)
                },
                insertResult: { result, display in
                    let insertText: String
                    if display == .insertAsQuote {
                        insertText = exteraAIQuoteText(result)
                    } else {
                        insertText = result
                    }
                    interfaceInteraction?.insertText(NSAttributedString(string: insertText))
                }
            )
        }))
    }

    return [
        item(text: exteraAIString("Extera.AI.MenuTranslate"), iconName: "Translate", actionKind: .translate(languageName: activeTranslateToLang ?? "English")),
        item(text: exteraAIString("Extera.AI.MenuRestyle"), iconName: "Customize", actionKind: .restyle),
        item(text: exteraAIString("Extera.AI.MenuProofread"), iconName: "FactCheck", actionKind: .proofread),
        item(text: exteraAIString("Extera.AI.MenuSummarize"), iconName: "Message", actionKind: .summarize)
    ]
}

@discardableResult
func exteraAIPresentComposeReplacement(
    controller: ChatControllerImpl?,
    context: AccountContext,
    composedInputText: ComposedRichMessage
) -> Bool {
    let store = ExteraAIStore.shared
    guard store.replaceTelegramAI else {
        return false
    }

    let instruction: String
    switch composedInputText {
    case let .plain(text, _):
        instruction = text
    case let .rich(instantPage):
        instruction = markdownStringFromInstantPage(instantPage)
    case .empty:
        return false
    }
    if instruction.isEmpty {
        return false
    }

    guard case .resolved(_) = exteraAIResolveBackend() else {
        return false
    }

    exteraAIPresentResult(
        context: context,
        title: exteraAIString("Extera.AI.Title"),
        action: .restyle,
        sourceText: instruction,
        present: { resultController in
            controller?.present(resultController, in: .window(.root))
        },
        displayUndo: { content in
            let undoController = UndoOverlayController(presentationData: context.sharedContext.currentPresentationData.with { $0 }, content: content, elevatedLayout: false, animateInAsReplacement: false, action: { _ in
                return true
            })
            controller?.present(undoController, in: .window(.root))
        },
        insertResult: { result, display in
            let replacement: String
            if display == .insertAsQuote {
                replacement = exteraAIQuoteText(result)
            } else {
                replacement = result
            }
            controller?.updateChatPresentationInterfaceState(animated: true, interactive: true, { state in
                return state.updatedInterfaceState { interfaceState in
                    return interfaceState.withUpdatedEffectiveInputState(chatTextInputState(fromComposedRichMessage: .plain(text: replacement, entities: [])))
                }
            })
        }
    )
    return true
}
