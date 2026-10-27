import Foundation
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import TelegramUIPreferences

extension ChatControllerImpl {
    /// Presents the PageBlocked screen whenever Block Ads intercepts a sponsored message
    /// in this chat; "Proceed" reveals that particular ad for the rest of the session.
    func setupExteraAdblock() {
        guard let adContext = self.chatDisplayNode.adMessagesContext as? ExteraAdblockAdMessagesContext else {
            return
        }
        self.exteraAdblockDisposable = (adContext.blockedAdEvents.get()
        |> deliverOnMainQueue).start(next: { [weak self] blockedAd in
            guard let self else {
                return
            }
            let presentationData = self.presentationData
            let proceed = {
                adContext.allowOnce(opaqueId: blockedAd.opaqueId)
            }
            let screen = ExteraPageBlockedScreen(theme: presentationData.theme, strings: presentationData.strings, url: blockedAd.url, onProceed: proceed)
            self.present(screen, in: .window(.root))
        })
    }
}
