import Foundation
import CoreLocation

struct WeatherResult {
    let temperatureCelsius: Float
    let isFromLocation: Bool
}

protocol WeatherServiceProtocol {
    var lastKnownWeather: WeatherResult? { get }
    func fetchWeather(latitude: Double, longitude: Double, completion: @escaping (Result<WeatherResult, Error>) -> Void)
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResult
}

final class WeatherService: WeatherServiceProtocol {

    static let cacheKey = "mj_cached_weather"
    static let cacheTimestampKey = "mj_cached_weather_ts"

    private let apiKey: String
    private let defaults: UserDefaults
    private(set) var lastKnownWeather: WeatherResult?

    init(apiKey: String = "c247dc8b8aaee1f5c2d1543f687b2f3b",
         defaults: UserDefaults = .standard) {
        self.apiKey = apiKey
        self.defaults = defaults
        self.lastKnownWeather = loadCachedWeather()
    }

    func fetchWeather(latitude: Double, longitude: Double,
                      completion: @escaping (Result<WeatherResult, Error>) -> Void) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&units=metric&APPID=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(WeatherError.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(WeatherError.noData))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let main = json?["main"] as? [String: Any]
                guard let temp = main?["temp"] as? Float else {
                    completion(.failure(WeatherError.parseFailed))
                    return
                }
                let result = WeatherResult(temperatureCelsius: temp, isFromLocation: true)
                self?.lastKnownWeather = result
                self?.cacheWeather(result)
                DispatchQueue.main.async { completion(.success(result)) }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResult {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&units=metric&APPID=\(apiKey)"
        guard let url = URL(string: urlString) else { throw WeatherError.invalidURL }

        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let main = json?["main"] as? [String: Any]
        guard let temp = main?["temp"] as? Float else { throw WeatherError.parseFailed }

        let result = WeatherResult(temperatureCelsius: temp, isFromLocation: true)
        lastKnownWeather = result
        cacheWeather(result)
        return result
    }

    // MARK: - Cache

    private func cacheWeather(_ result: WeatherResult) {
        defaults.set(result.temperatureCelsius, forKey: WeatherService.cacheKey)
        defaults.set(Date().timeIntervalSince1970, forKey: WeatherService.cacheTimestampKey)
    }

    private func loadCachedWeather() -> WeatherResult? {
        let ts = defaults.double(forKey: WeatherService.cacheTimestampKey)
        guard ts > 0 else { return nil }
        let temp = defaults.float(forKey: WeatherService.cacheKey)
        return WeatherResult(temperatureCelsius: temp, isFromLocation: true)
    }

    enum WeatherError: Error {
        case invalidURL
        case noData
        case parseFailed
    }
}
