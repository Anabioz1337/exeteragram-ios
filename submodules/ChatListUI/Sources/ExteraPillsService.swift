import Foundation
import CoreLocation
import SwiftSignalKit
import TelegramUIPreferences
import ExteraSearchToolkit

private let weatherCacheInterval: TimeInterval = 15.0 * 60.0

/// Reads the pill stack's live values: the weather pill's temperature and the crypto
/// pill's coin price. Weather responses are cached in the "exteraPills" defaults suite
/// for fifteen minutes, so reopening the search field never waits on the network.
public final class ExteraPillsService: NSObject, CLLocationManagerDelegate {
    private let defaults: UserDefaults
    private let locationManager = CLLocationManager()
    private var authorizationCompletion: ((Bool) -> Void)?
    private var locationCompletion: ((CLLocation?) -> Void)?

    public override init() {
        self.defaults = UserDefaults(suiteName: "exteraPills") ?? UserDefaults.standard
        super.init()
    }

    /// The temperature observed most recently, or nil when nothing fresh has been fetched.
    public var cachedTemperatureCelsius: Double? {
        let cachedAt = self.defaults.double(forKey: "weatherTemperatureTimestamp")
        guard cachedAt > 0.0, Date().timeIntervalSince1970 - cachedAt < weatherCacheInterval else {
            return nil
        }
        let value = self.defaults.double(forKey: "weatherTemperatureCelsius")
        return value.isFinite ? value : nil
    }

    /// Fetches the current temperature when the cache has expired. With the "current"
    /// location source this runs through the CLLocationManager permission flow and caches
    /// the answer for fifteen minutes.
    public func refreshWeather(location: ExteraWeatherLocation?, completion: @escaping () -> Void) {
        guard Date().timeIntervalSince1970 - self.defaults.double(forKey: "weatherTemperatureTimestamp") >= weatherCacheInterval else {
            completion()
            return
        }
        guard let location else {
            completion()
            return
        }
        switch location.source {
        case .manual:
            self.fetchWeather(latitude: location.latitude, longitude: location.longitude, completion: completion)
        case .current:
            let status = self.authorizationStatus(self.locationManager)
            if status == .notDetermined {
                self.authorizationCompletion = { [weak self] granted in
                    guard let self, granted else {
                        DispatchQueue.main.async(execute: completion)
                        return
                    }
                    self.requestCurrentLocation(completion: completion)
                }
                self.locationManager.delegate = self
                self.locationManager.requestWhenInUseAuthorization()
            } else if status == .denied || status == .restricted {
                completion()
            } else {
                self.requestCurrentLocation(completion: completion)
            }
        }
    }

    private func requestCurrentLocation(completion: @escaping () -> Void) {
        self.locationManager.delegate = self
        self.locationCompletion = { [weak self] location in
            guard let self else {
                return
            }
            guard let location else {
                DispatchQueue.main.async(execute: completion)
                return
            }
            self.fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, completion: completion)
        }
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        self.locationManager.requestLocation()
    }

    private func fetchWeather(latitude: Double, longitude: Double, completion: @escaping () -> Void) {
        ExteraWeatherService.currentWeather(latitude: latitude, longitude: longitude, completion: { [weak self] observation in
            if let observation {
                self?.defaults.set(observation.temperatureCelsius, forKey: "weatherTemperatureCelsius")
                self?.defaults.set(observation.conditionCode, forKey: "weatherConditionCode")
                self?.defaults.set(Date().timeIntervalSince1970, forKey: "weatherTemperatureTimestamp")
            }
            completion()
        })
    }

    private func authorizationStatus(_ manager: CLLocationManager) -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return manager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        if status == .notDetermined {
            return
        }
        let completion = self.authorizationCompletion
        self.authorizationCompletion = nil
        let granted = status == .authorizedWhenInUse || status == .authorizedAlways
        completion?(granted)
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.handleAuthorizationChange(self.authorizationStatus(manager))
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.handleAuthorizationChange(status)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let completion = self.locationCompletion
        self.locationCompletion = nil
        completion?(locations.last)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let completion = self.locationCompletion
        self.locationCompletion = nil
        completion?(nil)
    }
}

/// The label the crypto pill renders: the coin's USD price from the shared rates snapshot,
/// falling back to the coin symbol until a snapshot arrives.
public func exteraCryptoPillTitle(target: ExteraCryptoPillTargetCurrency, rates: ExteraRatesSnapshot) -> String {
    let symbol: String
    switch target {
    case .btc: symbol = "BTC"
    case .eth: symbol = "ETH"
    case .usd: symbol = "USDT"
    }
    guard let price = rates.cryptoUsd[symbol] else {
        return symbol
    }
    return "$" + ExteraResultFormatter.compactPrice(price)
}
