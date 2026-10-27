import Foundation
import UIKit
import TelegramCore
import SwiftSignalKit
import UrlEscaping

public struct ExternalMusicAlbumArtResourceId {
    public let title: String
    public let performer: String
    public let isThumbnail: Bool
    
    public init(title: String, performer: String, isThumbnail: Bool) {
        self.title = title
        self.performer = performer
        self.isThumbnail = isThumbnail
    }
    
    public var uniqueId: String {
        return "ext-album-art-\(self.isThumbnail ? "thumb" : "full")-\(self.title.replacingOccurrences(of: "/", with: "_"))-\(self.performer.replacingOccurrences(of: "/", with: "_"))"
    }
    
    public var hashValue: Int {
        return self.title.hashValue &* 31 &+ self.performer.hashValue
    }
}

public class ExternalMusicAlbumArtResource: Equatable {
    public let file: FileMediaReference?
    public let title: String
    public let performer: String
    public let isThumbnail: Bool
    
    public init(file: FileMediaReference?, title: String, performer: String, isThumbnail: Bool) {
        self.file = file
        self.title = title
        self.performer = performer
        self.isThumbnail = isThumbnail
    }
    
    public var id: EngineMediaResource.Id {
        return EngineMediaResource.Id(ExternalMusicAlbumArtResourceId(title: self.title, performer: self.performer, isThumbnail: self.isThumbnail).uniqueId)
    }

    public static func ==(lhs: ExternalMusicAlbumArtResource, rhs: ExternalMusicAlbumArtResource) -> Bool {
        if lhs.file?.media.fileId != rhs.file?.media.fileId {
            return false
        }
        if lhs.title != rhs.title {
            return false
        }
        if lhs.performer != rhs.performer {
            return false
        }
        if lhs.isThumbnail != rhs.isThumbnail {
            return false
        }
        return true
    }
}

public func fetchExternalMusicAlbumArtResource(engine: TelegramEngine, file: FileMediaReference?, resource: ExternalMusicAlbumArtResource) -> Signal<EngineMediaResource.Fetch.Result, EngineMediaResource.Fetch.Error> {
    return engine.resources.fetchAlbumCover(file: file, title: resource.title, performer: resource.performer, isThumbnail: resource.isThumbnail)
    |> `catch` { _ -> Signal<EngineMediaResource.Fetch.Result, EngineMediaResource.Fetch.Error> in
        return fetchItunesAlbumArtResource(engine: engine, resource: resource)
    }
}

/// Apple Music cover fallback for tracks that carry neither an embedded artwork nor a server-side
/// album thumb. Queries the public iTunes Search API (no key), promotes `artworkUrl100` to its
/// 600x600 variant and hands the image over as a temp file, which the `custom` resource machinery
/// then stores in the postbox resource store keyed by title/performer.
private func fetchItunesAlbumArtResource(engine: TelegramEngine, resource: ExternalMusicAlbumArtResource) -> Signal<EngineMediaResource.Fetch.Result, EngineMediaResource.Fetch.Error> {
    return Signal { subscriber in
        var term = ""
        if !resource.performer.isEmpty {
            term = resource.performer
        }
        if !resource.title.isEmpty {
            if !term.isEmpty {
                term += " "
            }
            term += resource.title
        }
        guard !term.isEmpty, let escapedTerm = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            subscriber.putError(.generic)
            return
        }

        let fetchDisposable = MetaDisposable()
        var searchSucceeded = false
        fetchDisposable.set(engine.resources.httpData(url: "https://itunes.apple.com/search?term=\(escapedTerm)&entity=song&limit=10").start(
            next: { data in
                guard let dict = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any], let results = (dict["results"] as? [Any]) as? [[String: Any]] else {
                    subscriber.putError(.generic)
                    return
                }
                searchSucceeded = true

                let performer = resource.performer.lowercased()
                let title = resource.title.lowercased()
                var matchedArtworkUrl: String?
                var fallbackArtworkUrl: String?
                for result in results {
                    guard let artworkUrl = result["artworkUrl100"] as? String, !artworkUrl.isEmpty else {
                        continue
                    }
                    let trackName = (result["trackName"] as? String)?.lowercased()
                    let artistName = (result["artistName"] as? String)?.lowercased()
                    let isExactMatch = trackName == title && (artistName == performer || performer.isEmpty)
                    if isExactMatch {
                        matchedArtworkUrl = artworkUrl
                        break
                    } else if trackName == title || artistName == performer, fallbackArtworkUrl == nil {
                        fallbackArtworkUrl = artworkUrl
                    }
                }

                let artworkUrl = matchedArtworkUrl ?? fallbackArtworkUrl
                guard let artworkUrl = artworkUrl else {
                    subscriber.putError(.generic)
                    return
                }

                let fullSizeUrl = artworkUrl.replacingOccurrences(of: "100x100bb", with: "600x600bb")
                fetchDisposable.set(engine.resources.httpData(url: fullSizeUrl).start(
                    next: { artworkData in
                        let file = EngineTempBox.shared.tempFile(fileName: "image.jpg")
                        let _ = try? artworkData.write(to: URL(fileURLWithPath: file.path))
                        subscriber.putNext(.moveTempFile(file: file))
                        subscriber.putCompletion()
                    },
                    error: { _ in
                        subscriber.putError(.generic)
                    }
                ))
            },
            error: { _ in
                subscriber.putError(.generic)
            },
            completed: {
                if !searchSucceeded {
                    subscriber.putError(.generic)
                }
            }
        ))

        return ActionDisposable {
            fetchDisposable.dispose()
        }
    }
}
