import Foundation
import TelegramPresentationData

public func exteraAIErrorTexts(strings: PresentationStrings, failure: ExteraAIGenerationFailure) -> (title: String, info: String) {
    switch failure {
    case .onDeviceUnavailable:
        return (strings.ExteraAI_OnDeviceStatusUnavailable, strings.ExteraAI_OnDeviceUnavailableInfo)
    case .request(let requestFailure):
        return exteraAIRequestErrorTexts(strings: strings, requestFailure: requestFailure)
    }
}

public func exteraAIRequestErrorTexts(strings: PresentationStrings, requestFailure: ExteraAIRequestFailure) -> (title: String, info: String) {
    switch requestFailure {
    case .http(let status):
        switch status {
        case 400:
            return (strings.ExteraAI_Error400Title, strings.ExteraAI_Error400Info)
        case 401:
            return (strings.ExteraAI_Error401Title, strings.ExteraAI_Error401Info)
        case 402:
            return (strings.ExteraAI_Error402Title, strings.ExteraAI_Error402Info)
        case 403:
            return (strings.ExteraAI_Error403Title, strings.ExteraAI_Error403Info)
        case 408:
            return (strings.ExteraAI_Error408Title, strings.ExteraAI_Error408Info)
        case 429:
            return (strings.ExteraAI_Error429Title, strings.ExteraAI_Error429Info)
        case 502:
            return (strings.ExteraAI_Error502Title, strings.ExteraAI_Error502Info)
        case 503:
            return (strings.ExteraAI_Error503Title, strings.ExteraAI_Error503Info)
        default:
            return (strings.ExteraAI_ErrorGenericTitle, strings.ExteraAI_ErrorGenericInfo)
        }
    case .network:
        return (strings.ExteraAI_ErrorNetworkTitle, strings.ExteraAI_ErrorNetworkInfo)
    case .parse:
        return (strings.ExteraAI_ErrorParsingTitle, strings.ExteraAI_ErrorParsingInfo)
    case .emptyResponse:
        return (strings.ExteraAI_ErrorEmptyTitle, strings.ExteraAI_ErrorEmptyInfo)
    }
}

public func exteraAIOnDeviceStatusText(strings: PresentationStrings, status: ExteraAIOnDeviceStatus) -> String {
    switch status {
    case .ready:
        return strings.ExteraAI_OnDeviceStatusReady
    case .downloading:
        return strings.ExteraAI_OnDeviceStatusDownload
    case .loading:
        return strings.ExteraAI_OnDeviceStatusLoading
    case .unavailable:
        return strings.ExteraAI_OnDeviceStatusUnavailable
    }
}
