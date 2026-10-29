import Foundation
import JavaScriptCore

private func exteraPluginRuntimeDescribed(_ value: JSValue) -> String {
    let text = value.toString()
    return text.count > 240 ? String(text.prefix(240)) + "…" : text
}

final class ExteraPluginScriptBridge: NSObject {
    private let logSink: (String) -> Void
    var onMessageHandler: JSValue?
    var lastException: JSValue?

    init(logSink: @escaping (String) -> Void) {
        self.logSink = logSink
    }

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
            self.logSink("log: \(text)")
        }
    }
}

/// Self-contained JavaScriptCore host for one extera plugin script. Builds the sandbox,
/// installs the `log(...)` / `onMessage(...)` globals, evaluates the source once and reports
/// load/call exceptions back to the caller.
public final class ExteraPluginEngine {
    private let bridge: ExteraPluginScriptBridge
    private let context: JSContext

    /// Non-nil when `evaluateScript` itself threw (syntax/runtime error at import time).
    public let loadError: String?
    /// Last exception raised while invoking the registered onMessage handler.
    public private(set) var callError: String?

    public init(pluginId: String, sourceCode: String, logSink: @escaping (String) -> Void = { _ in }) {
        let bridge = ExteraPluginScriptBridge(logSink: logSink)
        self.bridge = bridge
        let context = JSContext()!
        context.name = "extera-plugin:\(pluginId)"
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
            self.loadError = "Ошибка выполнения скрипта: \(exteraPluginRuntimeDescribed(exception))"
        } else {
            self.loadError = nil
        }
        self.context = context
    }

    /// True when the evaluated script registered an onMessage handler.
    public var hasMessageHandler: Bool {
        return self.bridge.onMessageHandler != nil
    }

    /// Invoke the handler with a message-shaped dictionary; reply must be a string to count.
    public func deliverIncoming(text: String, senderName: String, chatId: Int64) -> String? {
        guard let handler = self.bridge.onMessageHandler else {
            return nil
        }
        self.bridge.lastException = nil
        self.callError = nil
        let payload: [String: Any] = [
            "text": text,
            "sender": senderName,
            "chatId": chatId,
        ]
        let reply = handler.call(withArguments: [NSDictionary(dictionary: payload)])
        if let exception = self.bridge.lastException, !exception.isNull && !exception.isUndefined {
            self.callError = exteraPluginRuntimeDescribed(exception)
            return nil
        }
        if let reply, reply.isString {
            let replyText = reply.toString()
            return replyText.isEmpty ? nil : replyText
        }
        return nil
    }

    /// One-shot dry run used by the plugin editor's Test action; never touches live state.
    public static func testRun(sourceCode: String, sample: (text: String, sender: String, chatId: Int64)) -> (reply: String?, error: String?) {
        let engine = ExteraPluginEngine(pluginId: "testrun", sourceCode: sourceCode)
        if let loadError = engine.loadError {
            return (nil, loadError)
        }
        guard engine.hasMessageHandler else {
            return (nil, "Скрипт не зарегистрировал обработчик onMessage(...). Пример: onMessage(function(m){ return 'reply'; })")
        }
        guard let reply = engine.deliverIncoming(text: sample.text, senderName: sample.sender, chatId: sample.chatId) else {
            if let callError = engine.callError {
                return (nil, "Ошибка в обработчике: \(callError)")
            }
            return (nil, nil)
        }
        return (reply, nil)
    }
}
