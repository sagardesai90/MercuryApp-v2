import XCTest
import CoreBluetooth
@testable import Mercury_Jacket

final class BLEEventTests: XCTestCase {

    // MARK: - parseCharacteristicUpdate

    func testParseCharacteristicUpdateValid() {
        let uuid = CBUUID(string: "1234")
        let payload: [AnyObject] = ["device-id" as AnyObject, uuid, "42" as AnyObject]
        let result = BLEEvent.parseCharacteristicUpdate(from: payload)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.deviceID, "device-id")
        XCTAssertEqual(result?.uuid, uuid)
        XCTAssertEqual(result?.value, "42")
    }

    func testParseCharacteristicUpdateNil() {
        XCTAssertNil(BLEEvent.parseCharacteristicUpdate(from: nil))
    }

    func testParseCharacteristicUpdateWrongType() {
        XCTAssertNil(BLEEvent.parseCharacteristicUpdate(from: "not an array"))
    }

    func testParseCharacteristicUpdateTooFewElements() {
        let payload: [AnyObject] = ["device-id" as AnyObject]
        XCTAssertNil(BLEEvent.parseCharacteristicUpdate(from: payload))
    }

    // MARK: - parseDisconnect

    func testParseDisconnectValid() {
        let payload: [AnyObject] = ["device-id" as AnyObject, true as AnyObject]
        let result = BLEEvent.parseDisconnect(from: payload)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.deviceID, "device-id")
        XCTAssertTrue(result?.tryReconnect ?? false)
    }

    func testParseDisconnectFalse() {
        let payload: [AnyObject] = ["device-id" as AnyObject, false as AnyObject]
        let result = BLEEvent.parseDisconnect(from: payload)
        XCTAssertFalse(result?.tryReconnect ?? true)
    }

    func testParseDisconnectNil() {
        XCTAssertNil(BLEEvent.parseDisconnect(from: nil))
    }
}
