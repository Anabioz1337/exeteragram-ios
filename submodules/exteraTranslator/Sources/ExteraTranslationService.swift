import Foundation
import SwiftSignalKit
import TelegramCore

public enum ExteraTranslationError: Error {
    case generic
    case limitExceeded
}

public func exteraProviderLanguageCode(_ code: String) -> String {
    switch code {
    case "zh-Hans":
        return "zh-CN"
    case "zh-Hant":
        return "zh-TW"
    default:
        return code
    }
}

public enum ExteraTranslator {
    public static func translate(
        _ text: String,
        provider: ExteraTranslationProvider,
        fromLanguage: String = "auto",
        toLanguage: String
    ) -> Signal<String, ExteraTranslationError> {
        guard !text.isEmpty else {
            return .single(text)
        }
        let normalizedSource = fromLanguage.isEmpty ? "auto" : fromLanguage
        let normalizedTarget = exteraProviderLanguageCode(toLanguage)
        switch provider {
        case .google:
            return GoogleWebTranslationBackend.translate(text: text, fromLanguage: normalizedSource, toLanguage: normalizedTarget)
        case .yandex:
            return YandexWebTranslationBackend.translate(text: text, fromLanguage: normalizedSource, toLanguage: normalizedTarget)
        }
    }

    public static func translateWithCurrentPreferences(
        _ text: String,
        appLanguageCode: String?
    ) -> Signal<String, ExteraTranslationError> {
        let preferences = ExteraTranslatorSettings.shared.current
        return self.translate(
            text,
            provider: preferences.provider,
            toLanguage: ExteraTranslatorSettings.shared.effectiveTargetLanguage(appLanguageCode: appLanguageCode)
        )
    }
}

private func deliverOnMain(_ block: @escaping () -> Void) {
    Queue.mainQueue().async {
        block()
    }
}

private final class GoogleWebTranslationBackend {
    private static let deviceModels = [
        "Galaxy S6", "Galaxy S7", "Galaxy S8", "Galaxy S9", "Galaxy S10", "Galaxy S21",
        "Pixel 3", "Pixel 4", "Pixel 5",
        "OnePlus 6", "OnePlus 7", "OnePlus 8", "OnePlus 9", "Xperia XZ", "Xperia XZ2", "Xperia XZ3", "Xperia 1", "Xperia 5", "Xperia 10", "Xperia L4"
    ]
    private static let chromeVersions = [
        "111.0.5563.57", "94.0.4606.81", "80.0.3987.119", "69.0.3497.100", "92.0.4515.159", "71.0.3578.99"
    ]

    static func translate(text: String, fromLanguage: String, toLanguage: String) -> Signal<String, ExteraTranslationError> {
        return Signal { subscriber in
            var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")
            components?.queryItems = [
                URLQueryItem(name: "client", value: "gtx"),
                URLQueryItem(name: "sl", value: fromLanguage),
                URLQueryItem(name: "tl", value: toLanguage),
                URLQueryItem(name: "dt", value: "t"),
                URLQueryItem(name: "ie", value: "UTF-8"),
                URLQueryItem(name: "oe", value: "UTF-8"),
                URLQueryItem(name: "otf", value: "1"),
                URLQueryItem(name: "ssel", value: "0"),
                URLQueryItem(name: "tsel", value: "0"),
                URLQueryItem(name: "kc", value: "7"),
                URLQueryItem(name: "dt", value: "at"),
                URLQueryItem(name: "dt", value: "bd"),
                URLQueryItem(name: "dt", value: "ex"),
                URLQueryItem(name: "dt", value: "ld"),
                URLQueryItem(name: "dt", value: "md"),
                URLQueryItem(name: "dt", value: "qca"),
                URLQueryItem(name: "dt", value: "rw"),
                URLQueryItem(name: "dt", value: "rm"),
                URLQueryItem(name: "dt", value: "ss"),
                URLQueryItem(name: "q", value: text)
            ]
            guard let url = components?.url else {
                deliverOnMain {
                    subscriber.putError(.generic)
                }
                return EmptyDisposable
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(randomUserAgent(), forHTTPHeaderField: "User-Agent")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if (error as NSError?)?.code == NSURLErrorCancelled {
                    return
                }
                deliverOnMain {
                    if let result = Self.processResponse(data: data, response: response, error: error, originalText: text) {
                        subscriber.putNext(result)
                        subscriber.putCompletion()
                    } else {
                        subscriber.putError(Self.responseError(response: response, error: error))
                    }
                }
            }
            task.resume()
            return ActionDisposable {
                task.cancel()
            }
        }
    }

    private static func randomUserAgent() -> String {
        let androidVersion = Int.random(in: 6 ... 12)
        let deviceModel = deviceModels.randomElement() ?? deviceModels[0]
        let chromeVersion = chromeVersions.randomElement() ?? chromeVersions[0]
        return "Mozilla/5.0 (Linux; Android \(androidVersion); \(deviceModel)) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/\(chromeVersion) Mobile Safari/537.36"
    }

    private static func responseError(response: URLResponse?, error: Error?) -> ExteraTranslationError {
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
            return .limitExceeded
        }
        return .generic
    }

    private static func processResponse(data: Data?, response: URLResponse?, error: Error?, originalText: String) -> String? {
        guard error == nil, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data else {
            return nil
        }
        guard let array = try? JSONSerialization.jsonObject(with: data) as? [Any], let blocks = array.first as? [Any] else {
            return nil
        }
        var result = ""
        for block in blocks {
            guard let blockData = block as? [Any], let blockText = blockData.first as? String, !blockText.isEmpty, blockText != "null" else {
                continue
            }
            result += blockText
        }
        guard !result.isEmpty else {
            return nil
        }
        if originalText.hasPrefix("\n") {
            result = "\n" + result
        }
        return result
    }
}

private final class YandexWebTranslationBackend {
    static func translate(text: String, fromLanguage: String, toLanguage: String) -> Signal<String, ExteraTranslationError> {
        return Signal { subscriber in
            let effectiveFromLanguage = fromLanguage.isEmpty || fromLanguage == "auto" ? nil : exteraProviderLanguageCode(fromLanguage)
            let language: String
            if let effectiveFromLanguage, effectiveFromLanguage != toLanguage {
                language = "\(effectiveFromLanguage)-\(toLanguage)"
            } else {
                language = toLanguage
            }

            var components = URLComponents(string: "https://translate.yandex.net/api/v3/tr.json/translate")
            components?.queryItems = [
                URLQueryItem(name: "srv", value: "android"),
                URLQueryItem(name: "lang", value: language),
                URLQueryItem(name: "text", value: text),
                URLQueryItem(name: "format", value: "text")
            ]
            guard let url = components?.url else {
                deliverOnMain {
                    subscriber.putError(.generic)
                }
                return EmptyDisposable
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if (error as NSError?)?.code == NSURLErrorCancelled {
                    return
                }
                deliverOnMain {
                    if let result = Self.processResponse(data: data) {
                        subscriber.putNext(result)
                        subscriber.putCompletion()
                    } else {
                        subscriber.putError(Self.responseError(data: data, response: response, error: error))
                    }
                }
            }
            task.resume()
            return ActionDisposable {
                task.cancel()
            }
        }
    }

    private static func responseError(data: Data?, response: URLResponse?, error: Error?) -> ExteraTranslationError {
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
            return .limitExceeded
        }
        if let data, let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let code = object["code"] as? Int, code == 429 {
            return .limitExceeded
        }
        return .generic
    }

    private static func processResponse(data: Data?) -> String? {
        guard let data, let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let code = object["code"] as? Int, code == 200 else {
            return nil
        }
        guard let texts = object["text"] as? [String] else {
            return nil
        }
        return texts.first(where: { !$0.isEmpty })
    }
}

public final class ExteraHTTPInternalTranslationService: ExperimentalInternalTranslationService {
    private static let maxConcurrentRequests = 4

    public init() {
    }

    public func translate(texts: [AnyHashable: String], fromLang: String, toLang: String) -> Signal<[AnyHashable: String]?, NoError> {
        if texts.isEmpty {
            return .single([:])
        }

        let provider = ExteraTranslatorSettings.shared.current.provider
        var translated: [AnyHashable: String] = [:]
        var signal = Signal<Void, NoError>.single(Void())
        for chunk in Self.chunks(of: Array(texts), size: ExteraHTTPInternalTranslationService.maxConcurrentRequests) {
            signal = signal
            |> then(
                combineLatest(chunk.map { key, text -> Signal<(AnyHashable, String?), NoError> in
                    ExteraTranslator.translate(text, provider: provider, fromLanguage: fromLang, toLanguage: toLang)
                    |> map { result -> (AnyHashable, String?) in
                        return (key, result)
                    }
                    |> (catch { _ -> Signal<(AnyHashable, String?), NoError> in
                        return .single((key, nil))
                    })
                })
                |> map { results -> Void in
                    for (key, result) in results {
                        if let result {
                            translated[key] = result
                        }
                    }
                }
            )
        }
        return signal
        |> map { _ -> [AnyHashable: String]? in
            return translated
        }
    }

    private static func chunks(of values: [(AnyHashable, String)], size: Int) -> [[(AnyHashable, String)]] {
        guard size > 0 else {
            return [values]
        }
        var result: [[(AnyHashable, String)]] = []
        var index = 0
        while index < values.count {
            let upperBound = min(index + size, values.count)
            result.append(Array(values[index ..< upperBound]))
            index = upperBound
        }
        return result
    }
}
