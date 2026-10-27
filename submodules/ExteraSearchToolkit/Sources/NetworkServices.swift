import Foundation

public struct ExteraWeatherObservation {
    public let temperatureCelsius: Double
    public let conditionCode: Int
}

public struct ExteraGeoLocation {
    public let name: String
    public let countryCode: String
    public let latitude: Double
    public let longitude: Double
}

public enum ExteraWeatherService {
    private static let forecastEndpoint = "https://api.open-meteo.com/v1/forecast"
    private static let geocodingEndpoint = "https://geocoding-api.open-meteo.com/v1/search"

    public static func currentWeather(latitude: Double, longitude: Double, completion: @escaping (ExteraWeatherObservation?) -> Void) {
        var components = URLComponents(string: forecastEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code")
        ]
        performRequest(url: components.url!, completion: { payload in
            guard let current = payload["current"] as? [String: Any],
                  let temperature = current["temperature_2m"] as? Double,
                  let code = current["weather_code"] as? Int else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            let observation = ExteraWeatherObservation(temperatureCelsius: temperature, conditionCode: code)
            DispatchQueue.main.async {
                completion(observation)
            }
        })
    }

    public static func searchLocations(named query: String, completion: @escaping ([ExteraGeoLocation]) -> Void) {
        var components = URLComponents(string: geocodingEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "15"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        performRequest(url: components.url!, completion: { payload in
            guard let results = payload["results"] as? [[String: Any]] else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            let locations = results.compactMap({ entry -> ExterraGeoLocationValue? in
                guard let name = entry["name"] as? String,
                      let latitude = entry["latitude"] as? Double,
                      let longitude = entry["longitude"] as? Double else {
                    return nil
                }
                let country = entry["country_code"] as? String ?? ""
                return ExterraGeoLocationValue(name: name, countryCode: country, latitude: latitude, longitude: longitude)
            })
            let mapped = locations.map({ location -> ExteraGeoLocation in
                return ExteraGeoLocation(name: location.name, countryCode: location.countryCode, latitude: location.latitude, longitude: location.longitude)
            })
            DispatchQueue.main.async {
                completion(mapped)
            }
        })
    }

    private typealias ExterraGeoLocationValue = (name: String, countryCode: String, latitude: Double, longitude: Double)

    private static func performRequest(url: URL, completion: @escaping ([String: Any]) -> Void) {
        let task = URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
            guard let data, let payload = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                completion([:])
                return
            }
            completion(payload)
        })
        task.resume()
    }
}

public enum ExteraRatesService {
    private static let fiatEndpoint = "https://api.frankfurter.dev/v1/latest"
    private static let cryptoEndpoint = "https://api.coingecko.com/api/v3/simple/price"

    public static func latestFiatRatesPerUsd(completion: @escaping ([String: Double]) -> Void) {
        var components = URLComponents(string: fiatEndpoint)!
        components.queryItems = [URLQueryItem(name: "base", value: "USD")]
        performRequest(url: components.url!) { payload in
            guard let rates = payload["rates"] as? [String: Double] else {
                return
            }
            DispatchQueue.main.async {
                completion(rates)
            }
        }
    }

    public static func cryptoPricesInUsd(completion: @escaping ([String: Double]) -> Void) {
        var components = URLComponents(string: cryptoEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "ids", value: "bitcoin,ethereum,the-open-network,tether"),
            URLQueryItem(name: "vs_currencies", value: "usd")
        ]
        performRequest(url: components.url!) { payload in
            var prices: [String: Double] = [:]
            let mapping = ["bitcoin": "BTC", "ethereum": "ETH", "the-open-network": "TON", "tether": "USDT"]
            for (apiId, canonicalId) in mapping {
                guard let entry = payload[apiId] as? [String: Any], let usd = entry["usd"] as? Double else {
                    continue
                }
                prices[canonicalId] = usd
            }
            DispatchQueue.main.async {
                completion(prices)
            }
        }
    }

    private static func performRequest(url: URL, completion: @escaping ([String: Any]) -> Void) {
        let task = URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
            guard let data, let payload = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return
            }
            completion(payload)
        })
        task.resume()
    }
}
