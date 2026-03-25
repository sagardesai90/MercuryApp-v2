import XCTest
@testable import Mercury_Jacket

final class JacketTests: XCTestCase {

    // MARK: - Codable round-trip

    func testEncodeDecode() throws {
        let jacket = Jacket(id: "ABC-123", name: "Test Jacket")
        let data = try JSONEncoder().encode(jacket)
        let decoded = try JSONDecoder().decode(Jacket.self, from: data)
        XCTAssertEqual(decoded.id, "ABC-123")
        XCTAssertEqual(decoded.name, "Test Jacket")
    }

    func testEncodeDecodePreservesSettings() throws {
        let jacket = Jacket(id: "X", name: "J")
        jacket.updateSettingLocal(key: Jacket.VOICE_CONTROL, value: true)
        jacket.updateSettingLocal(key: Jacket.MOTION_CONTROL, value: false)

        let data = try JSONEncoder().encode(jacket)
        let decoded = try JSONDecoder().decode(Jacket.self, from: data)
        XCTAssertTrue(decoded.getSetting(key: Jacket.VOICE_CONTROL))
        XCTAssertFalse(decoded.getSetting(key: Jacket.MOTION_CONTROL))
    }

    // MARK: - Default settings

    func testDefaultSettings() {
        let jacket = Jacket(id: "1", name: "J")
        let settings = jacket.getSettings()
        XCTAssertFalse(settings[Jacket.VOICE_CONTROL] ?? true)
        XCTAssertTrue(settings[Jacket.LOCATION_REQUEST] ?? false)
        XCTAssertTrue(settings[Jacket.MOTION_CONTROL] ?? false)
    }

    func testGetSettingReturnsFalseForUnknownKey() {
        let jacket = Jacket(id: "1", name: "J")
        XCTAssertFalse(jacket.getSetting(key: 999))
    }

    // MARK: - Setting merge

    func testCustomSettingOverridesDefault() {
        let jacket = Jacket(id: "1", name: "J")
        jacket.updateSettingLocal(key: Jacket.LOCATION_REQUEST, value: false)
        XCTAssertFalse(jacket.getSetting(key: Jacket.LOCATION_REQUEST))
    }
}
