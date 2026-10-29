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

/// An `AdMessagesHistoryContext` that hides sponsored messages while Block Ads is enabled.
///
/// Every intercepted ad is counted once (per opaque id, per context lifetime) in the account's
/// extera settings, which is what the Block Ads row reports as Blocked Requests.
public final class ExteraAdblockAdMessagesContext: AdMessagesHistoryContext {
    private let accountManager: AccountManager<TelegramAccountManagerTypes>

    private let filteredState = Promise<(interPostInterval: Int32?, messages: [Message], startDelay: Int32?, betweenDelay: Int32?)>()

    private let baseState = Atomic<ExteraBaseAdState?>(value: nil)
    private let adBlockEnabled = Atomic<Bool>(value: false)
    private let countedIds = Atomic<Set<Data>>(value: Set())

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
            let _ = self.baseState.swap(ExteraBaseAdState(interPostInterval: interPostInterval, messages: messages, startDelay: startDelay, betweenDelay: betweenDelay))
            self.republish()
        }))

        self.settingsDisposable.set((accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraSettings])
        |> deliverOnMainQueue).start(next: { [weak self] sharedData in
            guard let self else {
                return
            }
            let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.exteraSettings]?.get(ExteraSettings.self) ?? ExteraSettings.defaultSettings
            let wasEnabled = self.adBlockEnabled.swap(settings.adBlockEnabled)
            if wasEnabled != settings.adBlockEnabled {
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

    private func republish() {
        guard let baseState = self.baseState.with({ $0 }) else {
            return
        }
        let enabled = self.adBlockEnabled.with({ $0 })

        var messages = baseState.messages
        var interceptedCount: Int32 = 0
        if enabled {
            messages = baseState.messages.filter { message in
                guard let adAttribute = message.adAttribute else {
                    return true
                }
                var insertedNew = false
                let _ = self.countedIds.modify { ids -> Set<Data> in
                    guard !ids.contains(adAttribute.opaqueId) else {
                        return ids
                    }
                    var ids = ids
                    ids.insert(adAttribute.opaqueId)
                    insertedNew = true
                    return ids
                }
                if insertedNew {
                    interceptedCount += 1
                }
                return false
            }
        }

        if interceptedCount > 0 {
            let accountManager = self.accountManager
            let _ = updateExteraSettingsInteractively(accountManager: accountManager, { settings in
                return settings.withUpdatedAdBlockBlockedRequests(settings.adBlockBlockedRequests.addingReportingOverflow(interceptedCount).partialValue)
            }).startStandalone()
        }

        self.filteredState.set(.single((baseState.interPostInterval, messages, baseState.startDelay, baseState.betweenDelay)))
    }
}
