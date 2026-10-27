import Foundation
import SwiftSignalKit
import TelegramCore
import TextFormat
import ExteraTranslator

extension ChatControllerImpl {
    /// Replaces the composer text with its translation from the extera
    /// translator, mirroring the AI-compose read/write round-trip
    /// (ChatControllerNode.openAICompose). Structured rich content that plain
    /// entities cannot express is left untouched.
    func translateComposeInputWithExtera() {
        var effectivePresentationInterfaceState = self.presentationInterfaceState
        if let textInputPanelNode = self.chatDisplayNode.textInputPanelNode {
            effectivePresentationInterfaceState = effectivePresentationInterfaceState.updatedInterfaceState { $0.withUpdatedEffectiveInputState(textInputPanelNode.inputTextState) }
        }

        let effectiveInputContent = effectivePresentationInterfaceState.interfaceState.effectiveInputState.content
        guard effectiveInputContent.isEntityExpressible() else {
            return
        }

        let effectiveInputText = expandedInputStateAttributedString(attributedString(from: effectiveInputContent))
        guard effectiveInputText.length != 0 else {
            return
        }
        let inputText = trimChatInputText(effectiveInputText)
        guard inputText.length != 0 else {
            return
        }

        let appLanguageCode = self.presentationData.strings.baseLanguageCode
        let _ = ExteraTranslator.translateWithCurrentPreferences(
            inputText.string,
            appLanguageCode: appLanguageCode
        ).start(next: { [weak self] translated in
            guard let self, !translated.isEmpty else {
                return
            }
            let entities = generateTextEntities(translated, enabledTypes: .all, currentEntities: [])
            self.updateChatPresentationInterfaceState(animated: true, interactive: true, { state in
                return state.updatedInterfaceState { interfaceState in
                    return interfaceState.withUpdatedEffectiveInputState(chatTextInputState(fromComposedRichMessage: .plain(text: translated, entities: entities)))
                }
            })
        }, error: { _ in
        })
    }
}
