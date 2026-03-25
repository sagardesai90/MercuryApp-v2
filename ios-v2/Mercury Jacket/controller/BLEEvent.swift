import CoreBluetooth

/// Typed BLE event payloads replacing the untyped `Any?` used by `EventManager`.
/// Existing code can continue using the string-based event system; new code should
/// prefer these types for compile-time safety.
enum BLEEvent {
    case adapterConnect
    case adapterDisconnect
    case scanFound(peripheral: CBPeripheral)
    case scanNotFound
    case unableBluetooth
    case deviceConnected(deviceID: String)
    case servicesDiscovered(deviceID: String)
    case deviceConnecting(deviceID: String)
    case deviceDisconnected(deviceID: String, tryReconnect: Bool)
    case characteristicUpdated(deviceID: String, uuid: CBUUID, value: String)
    case startUpdate

    /// Convenience to extract a `characteristicUpdated` from the legacy `Any?` payload.
    static func parseCharacteristicUpdate(from param: Any?) -> (deviceID: String, uuid: CBUUID, value: String)? {
        guard let arr = param as? [AnyObject],
              arr.count >= 3,
              let deviceID = arr[0] as? String,
              let uuid = arr[1] as? CBUUID,
              let value = arr[2] as? String else { return nil }
        return (deviceID, uuid, value)
    }

    /// Convenience to extract a `deviceDisconnected` from the legacy `Any?` payload.
    static func parseDisconnect(from param: Any?) -> (deviceID: String, tryReconnect: Bool)? {
        guard let arr = param as? [AnyObject],
              arr.count >= 2,
              let deviceID = arr[0] as? String else { return nil }
        let tryReconnect = arr[1] as? Bool ?? true
        return (deviceID, tryReconnect)
    }
}
