import Foundation
import SwiftSignalKit
import TelegramCore
import TelegramUIPreferences
import Postbox

private struct ExteraBaseAdState: Equatable {
    var interPostInterval: Int32?
    var messages: [Message]
    var startDelay: Int32?
    var betweenDelay: Int32?

    static func ==(lhs: ExteraBaseAdState, rhs: ExteraBaseAdState) -> Bool {
        if lhs.interPostInterval != rhs.interPostInterval || lhs.startDelay != rhs.startDelay || lhs.betweenDelay != rhs.betweenDelay || lhs.messages.count != rhs.messages.count {
            return false
        }
        for i in 0 ..< lhs.messages.count where lhs.messages[i].id != rhs.messages[i].id {
            return false
        }
        return true
    }
}

public struct ExteraBlockedAd: Equatable {
    public let opaqueId: Data
    public let url: String
}

/// An `AdMessagesHistoryContext` that hides sponsored messages while Block Ads is enabled.
///
/// Every intercepted ad is counted once (per opaque id, per context lifetime) in the account's
/// extera settings and published through `blockedAdEvents`, which the chat presents as the
/// PageBlocked screen. "Proceed" lets exactly that ad through for the rest of this chat session.
public final class ExteraAdblockAdMessagesContext: AdMessagesHistoryContext {
    private let accountManager: AccountManager<TelegramAccountManagerTypes>

    private let filteredState = Promise<(interPostInterval: Int32?, messages: [Message], startDelay: Int32?, betweenDelay: Int32?)>()
    public let blockedAdEvents = Promise<ExteraBlockedAd>()

    private let baseState = Atomic<ExteraBaseAdState?>(value: nil)
    private let adBlockEnabled = Atomic<Bool>(value: false)
    private let hasSettings = Atomic<Bool>(value: false)
    private let countedIds = Atomic<Set<Data>>(value: Set())
    private let allowedIds = Atomic<Set<Data>>(value: Set())

    private let stateDisposable = MetaDisposable()
    private let settingsDisposable = MetaDisposable()

    public init(account: Account, accountManager: AccountManager<TelegramAccountManagerTypes>, peerId: EnginePeer.Id, messageId: EngineMessage.Id? = nil, activateManually: Bool = false) {
        self.accountManager = accountManager

        super.init(account: account, peerId: peerId, messageId: messageId, activateManually: activateManually)

        self.stateDisposable.set((super.state
        |> deliverOnMainQueue).start(next: { [weak self] interPostInterval, messages, startDelay, betweenDelay in
            guard let self else {
                return
            }
            self.baseState.swap(ExteraBaseAdState(interPostInterval: interPostInterval, messages: messages, startDelay: startDelay, betweenDelay: betweenDelay))
            self.republish()
        }))

        self.settingsDisposable.set((accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraSettings])
        |> deliverOnMainQueue).start(next: { [weak self] sharedData in
            guard let self else {
                return
            }
            let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.exteraSettings]?.get(ExteraSettings.self) ?? ExteraSettings.defaultSettings
            let wasEnabled = self.adBlockEnabled.swap(settings.adBlockEnabled)
            let isFirst = !self.hasSettings.swap(true)
            if wasEnabled != settings.adBlockEnabled || isFirst {
                Queue.mainQueue().async {
                    self.republish()
                }
            }
        }))
    }

    deinit {
        self.stateDisposable.dispose()
        self.settingsDisposable.dispose()
    }

    override public var state: Signal<(interPostInterval: Int32?, messages: [Message], startDelay: Int32?, betweenDelay: Int32?), NoError> {
        return self.filteredState.get()
    }

    public func allowOnce(opaqueId: Data) {
        let _ = self.allowedIds.with { ids in
            var ids = ids
            ids.insert(opaqueId)
            return ids
        }
        Queue.mainQueue().async {
            self.republish()
        }
    }

    private func republish() {
        guard let baseState = self.baseState.with({ $0 }) else {
            return
        }
        let enabled = self.adBlockEnabled.with({ $0 })
        let allowed = self.allowedIds.with({ $0 })

        var messages = baseState.messages
        var intercepted: [ExteraBlockedAd] = []
        if enabled {
            messages = baseState.messages.filter { message in
                guard let adAttribute = message.adAttribute else {
                    return true
                }
                if allowed.contains(adAttribute.opaqueId) {
                    return true
                }
                let counted = self.countedIds.with { ids -> Bool in
                    if ids.contains(adAttribute.opaqueId) {
                        return true
                    }
                    var ids = ids
                    ids.insert(adAttribute.opaqueId)
                    return false
                }
                if !counted {
                    intercepted.append(ExteraBlockedAd(opaqueId: adAttribute.opaqueId, url: adAttribute.url))
                }
                return false
            }
        }

        if !intercepted.isEmpty {
            let accountManager = self.accountManager
            let increment = Int32(intercepted.count)
            let _ = updateExteraSettingsInteractively(accountManager: accountManager, { settings in
                return settings.withUpdatedAdBlockBlockedRequests(settings.adBlockBlockedRequests.addingReportingOverflow(increment).partialValue)
            }).startStandalone()
            self.blockedAdEvents.set(.single(intercepted[0]))
        }

        self.filteredState.set(.single((baseState.interPostInterval, messages, baseState.startDelay, baseState.betweenDelay)))
    }
}
