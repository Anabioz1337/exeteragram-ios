import Foundation

public func exteraAIErrorTexts(failure: ExteraAIGenerationFailure) -> (title: String, info: String) {
    switch failure {
    case .onDeviceUnavailable:
        return (exteraAIOnDeviceStatusText(status: .unavailable), exteraAIString("Extera.AI.OnDeviceUnavailableInfo"))
    case .request(let requestFailure):
        return exteraAIRequestErrorTexts(requestFailure: requestFailure)
    }
}

public func exteraAIRequestErrorTexts(requestFailure: ExteraAIRequestFailure) -> (title: String, info: String) {
    switch requestFailure {
    case .http(let status):
        switch status {
        case 400:
            return (exteraAIString("Extera.AI.Error400Title"), exteraAIString("Extera.AI.Error400Info"))
        case 401:
            return (exteraAIString("Extera.AI.Error401Title"), exteraAIString("Extera.AI.Error401Info"))
        case 402:
            return (exteraAIString("Extera.AI.Error402Title"), exteraAIString("Extera.AI.Error402Info"))
        case 403:
            return (exteraAIString("Extera.AI.Error403Title"), exteraAIString("Extera.AI.Error403Info"))
        case 408:
            return (exteraAIString("Extera.AI.Error408Title"), exteraAIString("Extera.AI.Error408Info"))
        case 429:
            return (exteraAIString("Extera.AI.Error429Title"), exteraAIString("Extera.AI.Error429Info"))
        case 502:
            return (exteraAIString("Extera.AI.Error502Title"), exteraAIString("Extera.AI.Error502Info"))
        case 503:
            return (exteraAIString("Extera.AI.Error503Title"), exteraAIString("Extera.AI.Error503Info"))
        default:
            return (exteraAIString("Extera.AI.ErrorGenericTitle"), exteraAIString("Extera.AI.ErrorGenericInfo"))
        }
    case .network:
        return (exteraAIString("Extera.AI.ErrorNetworkTitle"), exteraAIString("Extera.AI.ErrorNetworkInfo"))
    case .parse:
        return (exteraAIString("Extera.AI.ErrorParsingTitle"), exteraAIString("Extera.AI.ErrorParsingInfo"))
    case .emptyResponse:
        return (exteraAIString("Extera.AI.ErrorEmptyTitle"), exteraAIString("Extera.AI.ErrorEmptyInfo"))
    }
}

public func exteraAIOnDeviceStatusText(status: ExteraAIOnDeviceStatus) -> String {
    switch status {
    case .ready:
        return exteraAIString("Extera.AI.OnDeviceStatusReady")
    case .downloading:
        return exteraAIString("Extera.AI.OnDeviceStatusDownload")
    case .loading:
        return exteraAIString("Extera.AI.OnDeviceStatusLoading")
    case .unavailable:
        return exteraAIString("Extera.AI.OnDeviceStatusUnavailable")
    }
}
