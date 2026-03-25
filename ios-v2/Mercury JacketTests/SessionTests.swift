import XCTest
@testable import Mercury_Jacket

final class SessionTests: XCTestCase {

    // MARK: - Helpers

    private func makePoint(
        jacketTemp: Float = 22.0,
        ambientTemp: Float = 10.0,
        powerLevel: Int = 5000,
        powerOutputRaw: Int? = nil,
        activityLevel: Int = 0,
        mode: Int = 2,
        timestamp: Date = Date()
    ) -> SessionDataPoint {
        SessionDataPoint(
            timestamp: timestamp,
            jacketTempCelsius: jacketTemp,
            ambientTempCelsius: ambientTemp,
            powerLevel: powerLevel,
            powerOutputRaw: powerOutputRaw,
            activityLevel: activityLevel,
            mode: mode
        )
    }

    // MARK: - isActive

    func testIsActiveWhenEndDateNil() {
        let session = Session(id: "1", jacketName: "J", startDate: Date(),
                              endDate: nil, dataPoints: [])
        XCTAssertTrue(session.isActive)
    }

    func testIsNotActiveWhenEndDateSet() {
        let session = Session(id: "1", jacketName: "J", startDate: Date(),
                              endDate: Date(), dataPoints: [])
        XCTAssertFalse(session.isActive)
    }

    // MARK: - Duration

    func testDurationUsesEndDate() {
        let start = Date(timeIntervalSince1970: 1000)
        let end   = Date(timeIntervalSince1970: 4600)
        let session = Session(id: "1", jacketName: "J", startDate: start,
                              endDate: end, dataPoints: [])
        XCTAssertEqual(session.duration, 3600, accuracy: 0.01)
    }

    func testDurationUsesNowWhenActive() {
        let start = Date(timeIntervalSinceNow: -120)
        let session = Session(id: "1", jacketName: "J", startDate: start,
                              endDate: nil, dataPoints: [])
        XCTAssertEqual(session.duration, 120, accuracy: 2.0)
    }

    // MARK: - Averages

    func testAveragePowerEmptyDataPoints() {
        let session = Session(id: "1", jacketName: "J", startDate: Date(),
                              endDate: nil, dataPoints: [])
        XCTAssertEqual(session.averagePower0to10, 0)
    }

    func testAveragePowerWithData() {
        let points = [
            makePoint(powerLevel: 5000),
            makePoint(powerLevel: 10000),
        ]
        let session = Session(id: "1", jacketName: "J", startDate: Date(),
                              endDate: nil, dataPoints: points)
        XCTAssertEqual(session.averagePower0to10, 7.5, accuracy: 0.01)
    }

    func testAverageJacketTemp() {
        let points = [
            makePoint(jacketTemp: 20.0),
            makePoint(jacketTemp: 30.0),
        ]
        let session = Session(id: "1", jacketName: "J", startDate: Date(),
                              endDate: nil, dataPoints: points)
        XCTAssertEqual(session.averageJacketTempCelsius, 25.0, accuracy: 0.01)
    }

    func testAverageAmbientTemp() {
        let points = [
            makePoint(ambientTemp: 5.0),
            makePoint(ambientTemp: 15.0),
        ]
        let session = Session(id: "1", jacketName: "J", startDate: Date(),
                              endDate: nil, dataPoints: points)
        XCTAssertEqual(session.averageAmbientTempCelsius, 10.0, accuracy: 0.01)
    }

    // MARK: - tempDeltaCelsius

    func testTempDelta() {
        let points = [
            makePoint(jacketTemp: 25.0, ambientTemp: 10.0),
            makePoint(jacketTemp: 35.0, ambientTemp: 20.0),
        ]
        let session = Session(id: "1", jacketName: "J", startDate: Date(),
                              endDate: nil, dataPoints: points)
        XCTAssertEqual(session.tempDeltaCelsius, 15.0, accuracy: 0.01)
    }

    // MARK: - estimatedEnergyWh

    func testEstimatedEnergyEmptyDataPoints() {
        let session = Session(id: "1", jacketName: "J", startDate: Date(),
                              endDate: nil, dataPoints: [])
        XCTAssertEqual(session.estimatedEnergyWh, 0)
    }

    func testEstimatedEnergy() {
        let start = Date(timeIntervalSince1970: 0)
        let end   = Date(timeIntervalSince1970: 3600)
        let points = [
            makePoint(powerLevel: 5000),
            makePoint(powerLevel: 5000),
        ]
        let session = Session(id: "1", jacketName: "J", startDate: start,
                              endDate: end, dataPoints: points)
        // avg power = 5.0/10 = 0.5 fraction, 1h, 45W => 22.5Wh
        XCTAssertEqual(session.estimatedEnergyWh, 22.5, accuracy: 0.1)
    }

    // MARK: - Codable

    func testSessionEncodeDecode() throws {
        let session = Session(id: "test-id", jacketName: "Mercury",
                              startDate: Date(timeIntervalSince1970: 1000),
                              endDate: Date(timeIntervalSince1970: 2000),
                              dataPoints: [makePoint()])
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        XCTAssertEqual(decoded.id, "test-id")
        XCTAssertEqual(decoded.jacketName, "Mercury")
        XCTAssertEqual(decoded.dataPoints.count, 1)
        XCTAssertFalse(decoded.isActive)
    }
}
