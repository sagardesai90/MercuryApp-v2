import XCTest
@testable import Mercury_Jacket

final class WeatherServiceTests: XCTestCase {

    // MARK: - Mock

    final class MockWeatherService: WeatherServiceProtocol {
        var lastKnownWeather: WeatherResult?
        var nextResult: Result<WeatherResult, Error> = .failure(WeatherService.WeatherError.noData)

        func fetchWeather(latitude: Double, longitude: Double,
                          completion: @escaping (Result<WeatherResult, Error>) -> Void) {
            let result = nextResult
            if case .success(let weather) = result {
                lastKnownWeather = weather
            }
            DispatchQueue.main.async { completion(result) }
        }

        func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResult {
            switch nextResult {
            case .success(let weather):
                lastKnownWeather = weather
                return weather
            case .failure(let error):
                throw error
            }
        }
    }

    // MARK: - Tests

    func testMockSuccessUpdatesLastKnown() {
        let mock = MockWeatherService()
        let expected = WeatherResult(temperatureCelsius: 18.5, isFromLocation: true)
        mock.nextResult = .success(expected)

        let expectation = XCTestExpectation(description: "Weather fetch")
        mock.fetchWeather(latitude: 42, longitude: -71) { result in
            switch result {
            case .success(let weather):
                XCTAssertEqual(weather.temperatureCelsius, 18.5, accuracy: 0.01)
            case .failure:
                XCTFail("Expected success")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(mock.lastKnownWeather)
    }

    func testMockFailureDoesNotUpdateLastKnown() {
        let mock = MockWeatherService()
        mock.nextResult = .failure(WeatherService.WeatherError.parseFailed)

        let expectation = XCTestExpectation(description: "Weather fetch failure")
        mock.fetchWeather(latitude: 42, longitude: -71) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure:
                break
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNil(mock.lastKnownWeather)
    }

    func testCachePersistence() {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        let service = WeatherService(defaults: defaults)
        XCTAssertNil(service.lastKnownWeather)

        defaults.set(Float(15.0), forKey: WeatherService.cacheKey)
        defaults.set(Date().timeIntervalSince1970, forKey: WeatherService.cacheTimestampKey)

        let service2 = WeatherService(defaults: defaults)
        XCTAssertNotNil(service2.lastKnownWeather)
        XCTAssertEqual(service2.lastKnownWeather?.temperatureCelsius ?? 0, 15.0, accuracy: 0.01)
    }
}
