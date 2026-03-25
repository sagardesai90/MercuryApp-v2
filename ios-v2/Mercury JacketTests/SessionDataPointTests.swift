import XCTest
@testable import Mercury_Jacket

final class SessionDataPointTests: XCTestCase {

    // MARK: - powerLevel0to10

    func testPowerLevel0to10Zero() {
        let point = SessionDataPoint(
            timestamp: Date(), jacketTempCelsius: 20, ambientTempCelsius: 10,
            powerLevel: 0, powerOutputRaw: nil, activityLevel: 0, mode: 1
        )
        XCTAssertEqual(point.powerLevel0to10, 0, accuracy: 0.001)
    }

    func testPowerLevel0to10Max() {
        let point = SessionDataPoint(
            timestamp: Date(), jacketTempCelsius: 20, ambientTempCelsius: 10,
            powerLevel: 10000, powerOutputRaw: nil, activityLevel: 0, mode: 1
        )
        XCTAssertEqual(point.powerLevel0to10, 10, accuracy: 0.001)
    }

    func testPowerLevel0to10Mid() {
        let point = SessionDataPoint(
            timestamp: Date(), jacketTempCelsius: 20, ambientTempCelsius: 10,
            powerLevel: 5000, powerOutputRaw: nil, activityLevel: 0, mode: 1
        )
        XCTAssertEqual(point.powerLevel0to10, 5, accuracy: 0.001)
    }

    func testPowerLevel0to10ArbitraryValue() {
        let point = SessionDataPoint(
            timestamp: Date(), jacketTempCelsius: 20, ambientTempCelsius: 10,
            powerLevel: 3500, powerOutputRaw: nil, activityLevel: 0, mode: 1
        )
        XCTAssertEqual(point.powerLevel0to10, 3.5, accuracy: 0.001)
    }

    // MARK: - powerOutputWatts

    func testPowerOutputWattsNilWhenNoRaw() {
        let point = SessionDataPoint(
            timestamp: Date(), jacketTempCelsius: 20, ambientTempCelsius: 10,
            powerLevel: 5000, powerOutputRaw: nil, activityLevel: 0, mode: 1
        )
        XCTAssertNil(point.powerOutputWatts)
    }

    func testPowerOutputWattsNilWhenZero() {
        let point = SessionDataPoint(
            timestamp: Date(), jacketTempCelsius: 20, ambientTempCelsius: 10,
            powerLevel: 5000, powerOutputRaw: 0, activityLevel: 0, mode: 1
        )
        XCTAssertNil(point.powerOutputWatts)
    }

    func testPowerOutputWattsConversion() {
        let point = SessionDataPoint(
            timestamp: Date(), jacketTempCelsius: 20, ambientTempCelsius: 10,
            powerLevel: 5000, powerOutputRaw: 80, activityLevel: 0, mode: 1
        )
        XCTAssertEqual(point.powerOutputWatts, 8.0, accuracy: 0.01)
    }

    func testPowerOutputWattsSmallValue() {
        let point = SessionDataPoint(
            timestamp: Date(), jacketTempCelsius: 20, ambientTempCelsius: 10,
            powerLevel: 5000, powerOutputRaw: 5, activityLevel: 0, mode: 1
        )
        XCTAssertEqual(point.powerOutputWatts, 0.5, accuracy: 0.01)
    }

    // MARK: - Codable

    func testEncodeDecode() throws {
        let point = SessionDataPoint(
            timestamp: Date(timeIntervalSince1970: 1000),
            jacketTempCelsius: 22.5,
            ambientTempCelsius: 10.3,
            powerLevel: 7000,
            powerOutputRaw: 120,
            activityLevel: 1,
            mode: 3
        )
        let data = try JSONEncoder().encode(point)
        let decoded = try JSONDecoder().decode(SessionDataPoint.self, from: data)
        XCTAssertEqual(decoded.jacketTempCelsius, 22.5, accuracy: 0.01)
        XCTAssertEqual(decoded.ambientTempCelsius, 10.3, accuracy: 0.01)
        XCTAssertEqual(decoded.powerLevel, 7000)
        XCTAssertEqual(decoded.powerOutputRaw, 120)
        XCTAssertEqual(decoded.activityLevel, 1)
        XCTAssertEqual(decoded.mode, 3)
    }
}
