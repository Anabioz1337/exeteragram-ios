import Foundation
import SwiftSignalKit
import NaturalLanguage

public enum ExteraTranslationError {
    case invalidRequest
    case network
    case rateLimit
    case parsing
    case providerError
}

public struct ExteraTranslationResult: Equatable {
    public let text: String
    public let detectedLanguage: String?
}

/// Random mobile user agent pool, mirroring `TranslatorUtils.formatUserAgent`
/// from the Android fork: a fake Android build with one of several Chrome
/// versions, so the web endpoints answer with the desktop-style JSON payload.
private func exteraRandomUserAgent() -> String {
    let deviceModels = [
        "Galaxy S6", "Galaxy S7", "Galaxy S8", "Galaxy S9", "Galaxy S10", "Galaxy S21",
        "Pixel 3", "Pixel 4", "Pixel 5",
        "OnePlus 6", "OnePlus 7", "OnePlus 8", "OnePlus 9", "Xperia XZ", "Xperia XZ2", "Xperia XZ3",
        "Xperia 1", "Xperia 5", "Xperia 10", "Xperia L4"
    ]
    let chromeVersions = [
        "111.0.5563.57", "94.0.4606.81", "80.0.3987.119", "69.0.3497.100", "92.0.4515.159", "71.0.3578.99"
    ]
    let androidVersion = Int32.random(in: 6 ... 12)
    let deviceModel = deviceModels.randomElement() ?? deviceModels[0]
    let chromeVersion = chromeVersions.randomElement() ?? chromeVersions[0]
    return "Mozilla/5.0 (Linux; Android \(androidVersion); \(deviceModel)) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/\(chromeVersion) Mobile Safari/537.36"
}

private func exteraDetectedLanguage(of text: String) -> String? {
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(String(text.prefix(256)))
    if let language = recognizer.dominantLanguage, language.rawValue != "und" {
        return language.rawValue
    }
    return nil
}

private func exteraPercentEncode(_ value: String) -> String {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "+&")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
}

private func exteraRequest(_ url: URL, completion: @escaping (Result<Data, ExteraTranslationError>) -> Void) -> URLSessionTask {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(exteraRandomUserAgent(), forHTTPHeaderField: "User-Agent")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 15.0
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if error != nil {
            completion(.failure(.network))
            return
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(.network))
            return
        }
        if httpResponse.statusCode == 429 {
            completion(.failure(.rateLimit))
            return
        }
        guard (200 ... 299).contains(httpResponse.statusCode), let data else {
            completion(.failure(.providerError))
            return
        }
        completion(.success(data))
    }
    task.resume()
    return task
}

private func exteraParseGoogleTranslation(_ data: Data, originalText: String) -> Result<String, ExteraTranslationError> {
    guard let jsonArray = (try? JSONSerialization.jsonObject(with: data)) as? [Any] else {
        return .failure(.parsing)
    }
    guard let translationArray = jsonArray.first as? [Any] else {
        return .failure(.parsing)
    }
    var result = ""
    for element in translationArray {
        if let translationBlock = element as? [Any], translationBlock.count > 0, let blockText = translationBlock[0] as? String, blockText != "null", !blockText.isEmpty {
            result += blockText
        }
    }
    if originalText.hasPrefix("\n") {
        result = "\n" + result
    }
    return .success(result)
}

private func exteraParseYandexTranslation(_ data: Data) -> Result<(text: String, detected: String?), ExteraTranslationError> {
    guard let payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
        return .failure(.parsing)
    }
    guard let code = payload["code"] as? Int, code == 200, let textArray = payload["text"] as? [Any] else {
        return .failure(.providerError)
    }
    let text = textArray.compactMap { $0 as? String }.joined()
    guard !text.isEmpty else {
        return .failure(.parsing)
    }
    return .success((text, payload["lang"] as? String))
}

public func exteraTranslateText(
    text: String,
    provider: ExteraTranslationProvider,
    fromLanguage: String? = nil,
    toLanguage: String
) -> Signal<ExteraTranslationResult, ExteraTranslationError> {
    guard !text.isEmpty else {
        return .fail(.invalidRequest)
    }
    return Signal { subscriber in
        let task = Atomic<URLSessionTask?>(value: nil)
        Queue.concurrentDefaultQueue().async {
            let requestTask: URLSessionTask
            switch provider {
            case .google:
                let effectiveFromLanguage = fromLanguage ?? exteraDetectedLanguage(of: text) ?? "auto"
                let uri = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(exteraPercentEncode(effectiveFromLanguage))&tl=\(exteraPercentEncode(toLanguage))&dt=t&ie=UTF-8&oe=UTF-8&otf=1&ssel=0&tsel=0&kc=7&dt=at&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&q=\(exteraPercentEncode(text))"
                guard let url = URL(string: uri) else {
                    subscriber.putError(.invalidRequest)
                    return
                }
                requestTask = exteraRequest(url) { result in
                    switch result {
                    case let .success(data):
                        switch exteraParseGoogleTranslation(data, originalText: text) {
                        case let .success(translated):
                            subscriber.putNext(ExteraTranslationResult(text: translated, detectedLanguage: effectiveFromLanguage == "auto" ? nil : effectiveFromLanguage))
                            subscriber.putCompletion()
                        case let .failure(error):
                            subscriber.putError(error)
                        }
                    case let .failure(error):
                        subscriber.putError(error)
                    }
                }
            case .yandex:
                let effectiveFromLanguage = fromLanguage ?? exteraDetectedLanguage(of: text)
                var components = URLComponents(string: "https://translate.yandex.net/api/v1/tr.json/translate")
                var queryItems = [
                    URLQueryItem(name: "srv", value: "trphone"),
                    URLQueryItem(name: "format", value: "text"),
                    URLQueryItem(name: "text", value: text)
                ]
                if let effectiveFromLanguage {
                    queryItems.append(URLQueryItem(name: "lang", value: "\(effectiveFromLanguage)-\(toLanguage)"))
                } else {
                    queryItems.append(URLQueryItem(name: "lang", value: toLanguage))
                }
                components?.queryItems = queryItems
                guard let url = components?.url else {
                    subscriber.putError(.invalidRequest)
                    return
                }
                requestTask = exteraRequest(url) { result in
                    switch result {
                    case let .success(data):
                        switch exteraParseYandexTranslation(data) {
                        case let .success((translated, detected)):
                            let detectedLanguage = detected?.components(separatedBy: "-").first
                            subscriber.putNext(ExteraTranslationResult(text: translated, detectedLanguage: detectedLanguage))
                            subscriber.putCompletion()
                        case let .failure(error):
                            subscriber.putError(error)
                        }
                    case let .failure(error):
                        subscriber.putError(error)
                    }
                }
            }
            task.set(requestTask)
        }
        return ActionDisposable {
            if let requestTask = task.with({ $0 }) {
                requestTask.cancel()
            }
        }
    }
    |> runOn(Queue.mainQueue())
}
