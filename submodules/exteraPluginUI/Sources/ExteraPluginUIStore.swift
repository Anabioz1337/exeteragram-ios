import Foundation
import SwiftSignalKit

private struct ExteraPluginUIStoreState {
    var installedPlugins: [ExteraPluginUIDescriptor] = []
    var verifiedSourcesOnly = true
    var sorting: ExteraCatalogSorting = .recentlyUpdated
    var developerServerURL = ""
    var logs: [ExteraPluginLogEntry] = []
}

/// TODO(merge): replace with ExteraPluginCore's plugin registry and analysis service once that
/// module lands. The UI reads everything through this store, so the swap touches this file only.
public final class ExteraPluginUIStore {
    public static let shared = ExteraPluginUIStore()

    public let installedPlugins = ValuePromise<[ExteraPluginUIDescriptor]>([], ignoreRepeated: true)
    public let verifiedSourcesOnly = ValuePromise<Bool>(true, ignoreRepeated: true)
    public let sorting = ValuePromise<ExteraCatalogSorting>(.recentlyUpdated, ignoreRepeated: true)
    public let developerServerURL = ValuePromise<String>("", ignoreRepeated: true)
    public let logs = ValuePromise<[ExteraPluginLogEntry]>([], ignoreRepeated: true)

    private let maxLogEntries = 200
    private let stateLock = NSLock()
    private var state = ExteraPluginUIStoreState()

    private init() {
    }

    private var synchronizedState: ExteraPluginUIStoreState {
        get {
            self.stateLock.lock()
            defer {
                self.stateLock.unlock()
            }
            return self.state
        }
        set {
            self.stateLock.lock()
            self.state = newValue
            self.stateLock.unlock()
        }
    }

    public var installedPluginsValue: [ExteraPluginUIDescriptor] {
        return self.synchronizedState.installedPlugins
    }

    public var verifiedSourcesOnlyValue: Bool {
        return self.synchronizedState.verifiedSourcesOnly
    }

    public var sortingValue: ExteraCatalogSorting {
        return self.synchronizedState.sorting
    }

    public var developerServerURLValue: String {
        return self.synchronizedState.developerServerURL
    }

    public var logsValue: [ExteraPluginLogEntry] {
        return self.synchronizedState.logs
    }

    public func setEnabled(_ enabled: Bool, pluginId: String) {
        var updated = self.synchronizedState
        for index in updated.installedPlugins.indices {
            if updated.installedPlugins[index].id == pluginId {
                updated.installedPlugins[index].enabled = enabled
            }
        }
        self.synchronizedState = updated
        self.installedPlugins.set(updated.installedPlugins)
    }

    public func add(_ descriptor: ExteraPluginUIDescriptor) {
        var updated = self.synchronizedState
        guard !updated.installedPlugins.contains(where: { $0.id == descriptor.id }) else {
            return
        }
        updated.installedPlugins.append(descriptor)
        self.synchronizedState = updated
        self.installedPlugins.set(updated.installedPlugins)
    }

    public func setVerifiedSourcesOnly(_ verifiedOnly: Bool) {
        var updated = self.synchronizedState
        updated.verifiedSourcesOnly = verifiedOnly
        self.synchronizedState = updated
        self.verifiedSourcesOnly.set(verifiedOnly)
    }

    public func setSorting(_ sorting: ExteraCatalogSorting) {
        var updated = self.synchronizedState
        updated.sorting = sorting
        self.synchronizedState = updated
        self.sorting.set(sorting)
    }

    public func setDeveloperServerURL(_ url: String) {
        var updated = self.synchronizedState
        updated.developerServerURL = url
        self.synchronizedState = updated
        self.developerServerURL.set(url)
    }

    public func appendLog(_ text: String) {
        var updated = self.synchronizedState
        updated.logs.append(ExteraPluginLogEntry(timestamp: Date(), text: text))
        if updated.logs.count > self.maxLogEntries {
            updated.logs.removeFirst(updated.logs.count - self.maxLogEntries)
        }
        self.synchronizedState = updated
        self.logs.set(updated.logs)
    }
}
