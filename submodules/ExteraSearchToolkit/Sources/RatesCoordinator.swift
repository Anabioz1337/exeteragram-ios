import Foundation

/// Keeps one up-to-date rates snapshot alive while a consumer is active; both the inline
/// converter and the crypto pill read from it, so their live values agree.
public final class ExteraSearchRatesCoordinator {
    private struct FetchState {
        var fiatPerUsd: [String: Double]?
        var cryptoUsd: [String: Double]?
        var requestedAt: TimeInterval = -Double.greatestFiniteMagnitude

        mutating func reset() {
            self.requestedAt = Date().timeIntervalSinceReferenceDate
        }
    }

    private var state = FetchState()
    public var onChanged: () -> Void = {}

    private var currentSnapshot: ExteraRatesSnapshot {
        return ExteraRatesSnapshot(fiatPerUsd: self.state.fiatPerUsd ?? [:], cryptoUsd: self.state.cryptoUsd ?? [:])
    }

    private static let minimumRefreshInterval: TimeInterval = 600.0

    public init() {
    }

    public func activateSnapshot() -> ExteraRatesSnapshot {
        if Date().timeIntervalSinceReferenceDate - self.state.requestedAt > ExteraSearchRatesCoordinator.minimumRefreshInterval {
            self.refresh()
        }
        return self.currentSnapshot
    }

    private func refresh() {
        self.state.reset()

        let previousSnapshot = self.currentSnapshot
        let applyChange: ([String: Double]?, [String: Double]?) -> Void = { [weak self] fiatPerUsd, cryptoUsd in
            guard let strongSelf = self else {
                return
            }
            if let fiatPerUsd {
                strongSelf.state.fiatPerUsd = fiatPerUsd
            }
            if let cryptoUsd {
                strongSelf.state.cryptoUsd = cryptoUsd
            }
            let updatedSnapshot = strongSelf.currentSnapshot
            if updatedSnapshot.fiatPerUsd != previousSnapshot.fiatPerUsd || updatedSnapshot.cryptoUsd != previousSnapshot.cryptoUsd {
                strongSelf.onChanged()
            }
        }

        ExteraRatesService.latestFiatRatesPerUsd({ rates in
            applyChange(rates, nil)
        })
        ExteraRatesService.cryptoPricesInUsd({ prices in
            applyChange(nil, prices)
        })
    }
}
