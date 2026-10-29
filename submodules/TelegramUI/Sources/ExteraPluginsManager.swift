import Foundation
import SwiftSignalKit
import TelegramUIPreferences
import AccountContext
import UndoUI
import exteraPluginKit

final class ExteraPluginRuntime {
    let plugin: InstalledExteraPlugin
    private let engine: ExteraPluginEngine
    private(set) var consecutiveFailures = 0

    init(plugin: InstalledExteraPlugin) {
        self.plugin = plugin
        self.engine = ExteraPluginEngine(
            pluginId: plugin.id,
            sourceCode: plugin.sourceCode,
            logSink: { ExteraPluginsManager.shared.appendLog($0) }
        )
        if let loadError = self.engine.loadError {
            ExteraPluginsManager.shared.appendLog("\(plugin.name): ошибка загрузки — \(loadError)")
            self.consecutiveFailures += 1
        } else if !self.engine.hasMessageHandler {
            ExteraPluginsManager.shared.appendLog("\(plugin.name): обработчик onMessage(...) не зарегистрирован")
            self.consecutiveFailures += 1
        }
    }

    func deliverIncoming(text: String, senderName: String, chatId: Int64) -> String? {
        guard let reply = self.engine.deliverIncoming(text: text, senderName: senderName, chatId: chatId) else {
            if let callError = self.engine.callError {
                self.consecutiveFailures += 1
                ExteraPluginsManager.shared.appendLog("\(self.plugin.name): ошибка вызова — \(callError)")
            }
            return nil
        }
        self.consecutiveFailures = 0
        return reply
    }
}


public final class ExteraPluginsManager {
    public static let shared = ExteraPluginsManager()

    public static let maxFailuresBeforeDisable = 3
    public static let maxLogs = 200

    public let logs = ValuePromise<[String]>([], ignoreRepeated: true)

    private struct DeliveredKey: Hashable {
        let chatId: Int64
        let messageId: Int64

        init(chatId: Int64, messageId: Int64) {
            self.chatId = chatId
            self.messageId = messageId
        }
    }

    private weak var sharedContext: SharedAccountContext?
    private let settingsDisposable = MetaDisposable()
    private var runtimes: [ExteraPluginRuntime] = []
    private var logsBuffer: [String] = []
    private var deliveredKeys: [DeliveredKey] = []
    private let stateLock = NSLock()
    private static let maxDeliveredKeys = 1024

    private init() {}

    public func attach(sharedContext: SharedAccountContext) {
        self.stateLock.lock()
        defer {
            self.stateLock.unlock()
        }
        if self.sharedContext != nil {
            return
        }
        self.sharedContext = sharedContext
        self.settingsDisposable.set(
            (exteraPluginsSettings(accountManager: sharedContext.accountManager)
            |> deliverOnMainQueue
            |> map { settings -> [InstalledExteraPlugin] in
                return settings.enabledPlugins()
            }).start(next: { [weak self] plugins in
                guard let self else {
                    return
                }
                self.stateLock.lock()
                self.runtimes = plugins.map { ExteraPluginRuntime(plugin: $0) }
                self.stateLock.unlock()
            })
        )
    }

    public func appendLog(_ line: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        self.stateLock.lock()
        defer {
            self.stateLock.unlock()
        }
        self.logsBuffer.append("[\(timestamp)] \(line)")
        if self.logsBuffer.count > ExteraPluginsManager.maxLogs {
            self.logsBuffer.removeFirst(self.logsBuffer.count - ExteraPluginsManager.maxLogs)
        }
        self.logs.set(self.logsBuffer)
    }

    public func hasNoRuntimes() -> Bool {
        self.stateLock.lock()
        defer {
            self.stateLock.unlock()
        }
        return self.runtimes.isEmpty
    }

    func handleIncomingMessages(_ messages: [(text: String, sender: String, chatId: Int64, key: Int64)]) {
        for message in messages where !message.text.isEmpty {
            self.processOneIncoming(message)
        }
    }

    private func processOneIncoming(_ message: (text: String, sender: String, chatId: Int64, key: Int64)) {
        let key = DeliveredKey(chatId: message.chatId, messageId: message.key)
        self.stateLock.lock()
        if self.deliveredKeys.contains(key) {
            self.stateLock.unlock()
            return
        }
        self.deliveredKeys.append(key)
        if self.deliveredKeys.count > ExteraPluginsManager.maxDeliveredKeys {
            self.deliveredKeys.removeFirst(self.deliveredKeys.count - ExteraPluginsManager.maxDeliveredKeys)
        }
        let runtimesSnapshot = self.runtimes
        self.stateLock.unlock()

        for runtime in runtimesSnapshot {
            let reply = runtime.deliverIncoming(text: message.text, senderName: message.sender, chatId: message.chatId)
            if runtime.consecutiveFailures >= ExteraPluginsManager.maxFailuresBeforeDisable {
                self.disablePlugin(runtime.plugin.id)
            } else if let reply {
                self.presentReplyToast(pluginName: runtime.plugin.name, reply: reply)
            }
        }
    }

    private func presentReplyToast(pluginName: String, reply: String) {
        Queue.mainQueue().async { [weak sharedContext = self.sharedContext] in
            guard let sharedContext else {
                return
            }
            let presentationData = sharedContext.currentPresentationData.with { $0 }
            let controller = UndoOverlayController(
                presentationData: presentationData,
                content: .info(title: pluginName, text: reply, timeout: 3.5, customUndoText: nil),
                action: { _ in return false }
            )
            sharedContext.presentGlobalController(controller, nil)
        }
    }

    private func disablePlugin(_ pluginId: String) {
        guard let sharedContext = self.sharedContext else {
            return
        }
        let _ = updateExteraPluginsSettingsInteractively(accountManager: sharedContext.accountManager, { settings in
            return settings.withUpdatedEnabled(pluginId, false)
        }).startStandalone()
        self.appendLog("Плагин отключён автоматически после повторяющихся ошибок.")
    }
}
