import Foundation
import SwiftSignalKit
import TelegramCore

public struct LrcLine: Equatable {
    public let timestamp: Double?
    public let text: String

    public init(timestamp: Double?, text: String) {
        self.timestamp = timestamp
        self.text = text
    }
}

public struct TrackLyrics: Equatable {
    public let lines: [LrcLine]

    public init(lines: [LrcLine]) {
        self.lines = lines
    }
}

public enum TrackLyricsOutcome: Equatable {
    case found(TrackLyrics)
    case instrumental
    case notFound
    case failed
}

public func parseLrcContent(_ content: String) -> [LrcLine] {
    var parsedLines: [LrcLine] = []
    for rawLine in content.split(separator: "\n", omittingEmptySubsequences: true) {
        let line = Substring(rawLine)

        var index = line.startIndex
        var timestamps: [Double] = []
        var hadTag = false
        while index < line.endIndex, line[index] == "[" {
            guard let closingIndex = line[index...].firstIndex(of: "]") else {
                break
            }
            if let timestamp = lrcTimestamp(line[line.index(after: index)..<closingIndex]) {
                timestamps.append(timestamp)
            }
            hadTag = true
            index = line.index(after: closingIndex)
        }

        let text = String(line[index...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            continue
        }
        if timestamps.isEmpty && !hadTag {
            parsedLines.append(LrcLine(timestamp: nil, text: text))
        } else {
            for timestamp in timestamps {
                parsedLines.append(LrcLine(timestamp: timestamp, text: text))
            }
        }
    }
    return parsedLines.sorted { ($0.timestamp ?? .infinity) < ($1.timestamp ?? .infinity) }
}

private func lrcTimestamp(_ body: Substring) -> Double? {
    let parts = body.split(separator: ":", omittingEmptySubsequences: false)
    guard parts.count >= 2, let minutes = Int(parts[0].trimmingCharacters(in: .whitespaces)), minutes >= 0 else {
        return nil
    }
    let secondsValue = parts[1].replacingOccurrences(of: ",", with: ".")
    guard let seconds = Double(secondsValue.trimmingCharacters(in: .whitespaces)), seconds >= 0.0 else {
        return nil
    }
    var result = Double(minutes) * 60.0 + seconds
    if parts.count > 2, let frames = Double(parts[2].trimmingCharacters(in: .whitespaces)) {
        result += frames / 100.0
    }
    return result
}

private struct LrclibSearchResult {
    let trackName: String?
    let artistName: String?
    let duration: Double?
    let instrumental: Bool
    let syncedLyrics: String?
    let plainLyrics: String?

    var hasAnyLyrics: Bool {
        return !(self.syncedLyrics?.isEmpty ?? true) || !(self.plainLyrics?.isEmpty ?? true)
    }
}

private func parseLrclibSearchResults(_ data: Data) -> [LrclibSearchResult]? {
    guard let payload = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
        return nil
    }
    return payload.map { entry in
        LrclibSearchResult(
            trackName: entry["trackName"] as? String,
            artistName: entry["artistName"] as? String,
            duration: entry["duration"] as? Double,
            instrumental: entry["instrumental"] as? Bool ?? false,
            syncedLyrics: entry["syncedLyrics"] as? String,
            plainLyrics: entry["plainLyrics"] as? String
        )
    }
}

private func selectBestLrclibResult(_ results: [LrclibSearchResult], title: String, performer: String, trackDuration: Double?) -> LrclibSearchResult? {
    let loweredTitle = title.lowercased()
    let loweredPerformer = performer.lowercased()

    var bestResult: LrclibSearchResult?
    var bestScore = -1
    for result in results where result.hasAnyLyrics {
        var score = 0
        if !(result.syncedLyrics?.isEmpty ?? true) {
            score += 3
        } else {
            score += 1
        }
        if let trackName = result.trackName?.lowercased() {
            if trackName == loweredTitle {
                score += 4
            } else if !loweredTitle.isEmpty && trackName.contains(loweredTitle) {
                score += 1
            }
        }
        if let artistName = result.artistName?.lowercased() {
            if artistName == loweredPerformer {
                score += 4
            } else if !loweredPerformer.isEmpty && artistName.contains(loweredPerformer) {
                score += 1
            }
        }
        if let trackDuration = trackDuration, trackDuration > 0.0, let duration = result.duration {
            if abs(duration - trackDuration) <= 2.0 {
                score += 3
            }
        }
        if score > bestScore {
            bestScore = score
            bestResult = result
        }
    }
    return bestResult
}

/// Queries the public LRCLIB catalog for synced lyrics of a track (no key required).
/// Synced `LRC` content wins over plain text, name matches are preferred over partial ones,
/// and entries within +-2 s of the playing duration win ties.
public func fetchTrackLyrics(engine: TelegramEngine, title: String, performer: String, trackDuration: Double?) -> Signal<TrackLyricsOutcome, NoError> {
    var queryComponents: [String] = []
    if !performer.isEmpty {
        queryComponents.append(performer)
    }
    if !title.isEmpty {
        queryComponents.append(title)
    }
    let query = queryComponents.joined(separator: " ")
    guard !query.isEmpty, var requestComponents = URLComponents(string: "https://lrclib.net/api/search") else {
        return .single(.notFound)
    }
    requestComponents.queryItems = [URLQueryItem(name: "q", value: query)]
    guard let requestUrl = requestComponents.string else {
        return .single(.notFound)
    }

    return Signal { subscriber in
        var finished = false
        var requestSeen = false
        let finishEmitting: (TrackLyricsOutcome) -> Void = { outcome in
            guard !finished else {
                return
            }
            finished = true
            subscriber.putNext(outcome)
            subscriber.putCompletion()
        }

        let disposable = MetaDisposable()
        disposable.set(engine.resources.httpData(url: requestUrl).start(
            next: { data in
                requestSeen = true
                guard !finished, let results = parseLrclibSearchResults(data) else {
                    finishEmitting(.failed)
                    return
                }
                guard let best = selectBestLrclibResult(results, title: title, performer: performer, trackDuration: trackDuration) else {
                    finishEmitting(.notFound)
                    return
                }
                if let syncedLyrics = best.syncedLyrics, !syncedLyrics.isEmpty {
                    let lines = parseLrcContent(syncedLyrics)
                    if !lines.isEmpty {
                        finishEmitting(.found(TrackLyrics(lines: lines)))
                        return
                    }
                }
                if let plainLyrics = best.plainLyrics, !plainLyrics.isEmpty {
                    let lines = plainLyrics.split(separator: "\n", omittingEmptySubsequences: true).map {
                        LrcLine(timestamp: nil, text: $0.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    finishEmitting(lines.isEmpty ? .notFound : .found(TrackLyrics(lines: lines)))
                    return
                }
                if best.instrumental {
                    finishEmitting(.instrumental)
                    return
                }
                finishEmitting(.notFound)
            },
            error: { _ in
                finishEmitting(.failed)
            },
            completed: {
                if !requestSeen {
                    finishEmitting(.failed)
                }
            }
        ))

        return ActionDisposable {
            disposable.dispose()
        }
    }
}
