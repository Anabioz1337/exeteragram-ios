import Foundation
import JavaScriptCore
import SwiftSignalKit
import TelegramUIPreferences
import AccountContext
import UndoUI

private final class ExteraPluginScriptBridge: NSObject {
    var onMessageHandler: JSValue?
    var lastException: JSValue?

    @objc func registerOnMessage(_ handler: JSValue) {
        guard handler.isFunction else {
            return
        }
        self.onMessageHandler = handler
    }

    @objc func reportError(_ error: JSValue) {
        self.lastException = error
    }

    @objc func log(_ text: String) {
        if !text.isEmpty {
            ExteraPluginsManager.shared.appendLog("log: \(text)")
        }
    }
}

final class ExteraPluginRuntime {
    let plugin: InstalledExteraPlugin
    private let bridge = ExteraPluginScriptBridge()
    private(set) var consecutiveFailures = 0

    init(plugin: InstalledExteraPlugin) {
        self.plugin = plugin

        let context = JSContext()!
        context.name = "extera-plugin:\(plugin.id)"
        context.exceptionHandler = { [weak bridge] _, exception in
            if !exception.isNull && !exception.isUndefined {
                bridge?.lastException = exception
            }
        }
        context.globalObject.setObject(
            self.bridge,
            forKeyedSubscript: "__extera" as NSString
        )
        context.evaluateScript("""
        var log = function(text) { __extera.log(String(text)); };
        var onMessage = function(handler) { __extera.registerOnMessage(handler); };
        """)
        context.evaluateScript(plugin.sourceCode)
        if let exception = self.bridge.lastException, !exception.isNull && !exception.isUndefined {
            ExteraPluginsManager.shared.appendLog("\(plugin.name): ошибка загрузки — \(runtimeDescribed(exception))")
            self.consecutiveFailures += 1
        }
        self.context = context
    }

    private let context: JSContext

    func deliverIncoming(text: String, senderName: String, chatId: Int64) -> String? {
        guard let handler = self.bridge.onMessageHandler else {
            return nil
        }
        self.bridge.lastException = nil
        let payload: [String: Any] = [
            "text": text,
            "sender": senderName,
            "chatId": chatId
        ]
        let reply = handler.call(withArguments: [NSDictionary(dictionary: payload)])
        if let exception = self.bridge.lastException, !exception.isNull && !exception.isUndefined {
            self.consecutiveFailures += 1
            ExteraPluginsManager.shared.appendLog("\(self.plugin.name): ошибка вызова — \(runtimeDescribed(exception))")
            return nil
        }
        self.consecutiveFailures = 0
        if let reply, reply.isString {
            let replyText = reply.toString()
            return replyText.isEmpty ? nil : replyText
        }
        return nil
    }
}

private func runtimeDescribed(_ value: JSValue) -> String {
    let text = value.toString()
    return text.count > 240 ? String(text.prefix(240)) + "…" : text
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

    public static func testRun(sourceCode: String, sample: (text: String, sender: String, chatId: Int64)) -> (reply: String?, error: String?) {
        let bridge = ExteraPluginScriptBridge()
        let context = JSContext()!
        context.exceptionHandler = { [weak bridge] _, exception in
            if !exception.isNull && !exception.isUndefined {
                bridge?.lastException = exception
            }
        }
        context.globalObject.setObject(bridge, forKeyedSubscript: "__extera" as NSString)
        context.evaluateScript("""
        var log = function(text) { __extera.log(String(text)); };
        var onMessage = function(handler) { __extera.registerOnMessage(handler); };
        """)
        context.evaluateScript(sourceCode)

        if let exception = bridge.lastException, !exception.isNull && !exception.isUndefined {
            return (nil, "Ошибка выполнения скрипта: \(runtimeDescribed(exception))")
        }
        guard let handler = bridge.onMessageHandler else {
            return (nil, "Скрипт не зарегистрировал обработчик onMessage(...). Пример: onMessage(function(m){ return 'reply'; })")
        }
        bridge.lastException = nil
        let payload: [String: Any] = [
            "text": sample.text,
            "sender": sample.sender,
            "chatId": sample.chatId
        ]
        let reply = handler.call(withArguments: [NSDictionary(dictionary: payload)])
        if let exception = bridge.lastException, !exception.isNull && !exception.isUndefined {
            return (nil, "Ошибка в обработчике: \(runtimeDescribed(exception))")
        }
        if let reply, reply.isString {
            return (reply.toString(), nil)
        }
        return (nil, nil)
    }
}
