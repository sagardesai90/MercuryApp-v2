//
//  BluetoothController.swift
//  MercuryJacket
//
//  Created by André Ponce on 12/11/2018.
//  Copyright © 2018 Quarky. All rights reserved.
//

import UIKit
import CoreBluetooth
import LoginWithAmazon
import SwiftyJSON
import Alamofire

class BluetoothController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, AIAuthenticationDelegate {

    private let TAG: String = "BluetoothController"
    // Accept any Mercury-branded device name (e.g. "Mercury Jacket", "Mercury Vest", "Mercury Pro", etc.)
    private func isMercuryDevice(name: String) -> Bool {
        return name.lowercased().hasPrefix("mercury")
    }
    private let SCAN_TIME: Int = 20
    private let READ_TIME: Int = 3
    private let ALEXA_URL: String = "https://x0i55e3ypk.execute-api.us-east-1.amazonaws.com/prod/?email=%@"

    private static var instance: BluetoothController?

    class Events {
        public static var ON_ADAPTER_CONNECT: String       = "onAdapterConnect"
        public static var ON_ADAPTER_DISCONNECT: String    = "onAdapterDisconnect"
        public static var ON_SCAN_FOUND: String            = "onScanFound"
        public static var ON_SCAN_NOT_FOUND: String        = "onScanNotFound"
        public static var ON_UNABLE_BLUETOOTH: String      = "onUnableBluetooth"
        public static var ON_DEVICE_CONNECTED: String      = "onDeviceConnected"
        public static var ON_SERVICES_DICOVERED: String    = "onServicesDiscovered"
        public static var ON_DEVICE_CONNECTING: String     = "onDeviceConnecting"
        public static var ON_DEVICE_DISCONNECTED: String   = "onDeviceDisconnected"
        public static var ON_UPDATE_CHARACTERISTIC: String = "onUpdateCharacteristic"
        public static var ON_START_UPDATE: String          = "onStartUpdate"
    }

    private var eventsManager: EventManager = EventManager()
    private var manager: CBCentralManager!

    // Per-device state keyed by CBPeripheral.identifier.uuidString
    private var devices: [String: CBPeripheral] = [:]
    private var characteristicsDic: [String: [CBUUID: CBCharacteristic]] = [:]
    private var characteristicValuesDic: [String: [CBUUID: String]] = [:]
    private var readCharacteristicDic: [String: [CBUUID: Int]] = [:]
    private var writingCharacteristicDic: [String: [CBUUID: Int]] = [:]
    private var readTimers: [String: Timer] = [:]

    private var connectedDeviceIDs: Set<String> = []
    private var pendingConnectionIDs: Set<String> = []     // known UUIDs awaiting BLE connect
    private var cancellingForReconnect: Set<String> = []   // devices cancelled to force fresh BLE handshake
    private var pairingErrorCounts: [String: Int] = [:]    // tracks consecutive error-14 failures per device
    private let MAX_PAIRING_RETRIES = 3
    private var connectionStartTimes: [String: Date] = [:] // tracks when each device connected
    private var scanning: Bool = false
    private var scanningForNew: Bool = false              // scanning for an unregistered new device

    private var scanTimer: Timer?
    private var adapterAlert: Alert!

    private var amazon_email: String? = nil
    private var amazonQueue: DataRequest? = nil

    public var adapterIsEnabled: Bool = false

    // MARK: - Lifecycle

    override init() {
        super.init()
        print("BluetoothController constructor")
        BluetoothController.instance = self
        resetCBManager()
    }

    public static func getInstance() -> BluetoothController {
        return instance!
    }

    private func resetCBManager() {
        self.manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    // MARK: - Public API

    /// Returns the cached value for the currently-selected jacket's characteristic.
    public func getValue(uuid: CBUUID) -> Int {
        return getValue(uuid: uuid, deviceID: AppController.getCurrentJacket()?.id)
    }

    public func getValue(uuid: CBUUID, deviceID: String?) -> Int {
        guard let id = deviceID else { return 0 }
        return Int(characteristicValuesDic[id]?[uuid] ?? "0") ?? 0
    }

    /// True when the currently-selected jacket is BLE-connected.
    public func isConnected() -> Bool {
        guard let id = AppController.getCurrentJacket()?.id else { return false }
        return connectedDeviceIDs.contains(id)
    }

    public func isConnected(deviceID: String) -> Bool {
        return connectedDeviceIDs.contains(deviceID)
    }

    public func getCharacteristics() -> [CBUUID: CBCharacteristic] {
        guard let id = AppController.getCurrentJacket()?.id else { return [:] }
        return characteristicsDic[id] ?? [:]
    }

    public func getCharacteristics(deviceID: String) -> [CBUUID: CBCharacteristic] {
        return characteristicsDic[deviceID] ?? [:]
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("BLUETOOTH STATUS:", central.state)
        switch central.state {
        case .poweredOn:
            print("Bluetooth is on.")
            self.adapterIsEnabled = true
            self.eventsManager.trigger(eventName: Events.ON_ADAPTER_CONNECT)
            if adapterAlert != nil {
                adapterAlert.dismiss()
                adapterAlert = nil
            }
        case .poweredOff:
            print("Bluetooth is Off.")
            self.adapterIsEnabled = false
            self.eventsManager.trigger(eventName: Events.ON_ADAPTER_DISCONNECT)
            for deviceID in Array(connectedDeviceIDs) {
                stopDeviceConnection(deviceID: deviceID)
                eventsManager.trigger(eventName: Events.ON_DEVICE_DISCONNECTED,
                                      information: [deviceID, true] as [AnyObject])
            }
            adapterAlert = Alert(context: AppController.getContext())
            adapterAlert.create(message: "Bluetooth is required to use this app, would you like to continue using this app?", type: Alert.ASK)
            adapterAlert.setActionListener(listener: Alert.ActionListener(onActionClick: { (action) in
                if action == Alert.YES_ACTION {
                    self.resetCBManager()
                } else {
                    exit(0)
                }
                self.adapterAlert = nil
            }))
            adapterAlert.show()
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let peripheralID = peripheral.identifier.uuidString
        print("SCANNED", peripheral.name ?? "<no name>", peripheralID.prefix(8))

        // Reconnect to a known registered device
        if pendingConnectionIDs.contains(peripheralID) && !connectedDeviceIDs.contains(peripheralID) {
            pendingConnectionIDs.remove(peripheralID)
            connect(peripheral: peripheral)
            if pendingConnectionIDs.isEmpty && !scanningForNew {
                manager.stopScan()
                scanning = false
                stopScanTimer()
            }
            return
        }

        // New device pairing — match by BLE name prefix OR Mercury service UUID in advertisement,
        // to handle firmware variants that don't include the device name in the advertisement packet.
        if scanningForNew {
            let name = peripheral.name ?? ""
            let advertisedServiceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
            let looksLikeMercury = isMercuryDevice(name: name)
                || advertisedServiceUUIDs.contains(JacketGattAttributes.serviceCBUUID)
            if looksLikeMercury {
                let saved = UserDefaults.standard.dictionary(forKey: AppController.KEY_JACKETS) as? [String: String]
                if saved == nil || saved![peripheralID] == nil {
                    print("DEVICE FOUND", "Name: \"\(name.isEmpty ? "<no name>" : name)\", Identifier: \(peripheralID)")
                    scanningForNew = false
                    if pendingConnectionIDs.isEmpty {
                        manager.stopScan()
                        scanning = false
                        stopScanTimer()
                    }
                    eventsManager.trigger(eventName: Events.ON_SCAN_FOUND, information: peripheral)
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("*****************************")
        print("Connection complete:", peripheral.identifier.uuidString)

        let deviceID = peripheral.identifier.uuidString
        connectedDeviceIDs.insert(deviceID)
        devices[deviceID] = peripheral
        connectionStartTimes[deviceID] = Date()
        peripheral.delegate = self
        pairingErrorCounts.removeValue(forKey: deviceID)  // successful connect clears error streak
        if characteristicValuesDic[deviceID] == nil { characteristicValuesDic[deviceID] = [:] }

        // Event carries deviceID so listeners can filter by their specific jacket
        eventsManager.trigger(eventName: Events.ON_DEVICE_CONNECTED, information: deviceID)
        peripheral.discoverServices([JacketGattAttributes.serviceCBUUID])

        if pendingConnectionIDs.isEmpty && !scanningForNew && scanning {
            manager.stopScan()
            scanning = false
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let deviceID = peripheral.identifier.uuidString
        let errorCode = (error as NSError?)?.code ?? -1
        print("Failed to connect \(deviceID.prefix(8)) error code \(errorCode):", error as Any)

        // CBError code 14 — "Peer removed pairing information": the vest cleared its bonding
        // cache (firmware bug). iOS is trying to reconnect with stale keys that the vest
        // no longer recognizes. Retry a few times in case iOS re-initiates fresh pairing,
        // but give up after MAX_PAIRING_RETRIES and tell the user to forget the device in
        // iOS Settings → Bluetooth so a clean pairing can be established.
        if errorCode == 14 {
            let count = (pairingErrorCounts[deviceID] ?? 0) + 1
            pairingErrorCounts[deviceID] = count
            if count <= MAX_PAIRING_RETRIES {
                print("Peer removed pairing info — retry \(count)/\(MAX_PAIRING_RETRIES) for \(deviceID.prefix(8))")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.manager.connect(peripheral, options: nil)
                }
                return
            }
            // Exhausted retries — iOS is stuck with stale bonding keys. The user must
            // forget the device in iOS Settings → Bluetooth so iOS clears its bond store.
            print("Pairing retries exhausted for \(deviceID.prefix(8)) — prompting user to forget device")
            pairingErrorCounts.removeValue(forKey: deviceID)
            pendingConnectionIDs.remove(deviceID)
            // Look up the user-assigned name for a friendlier error message
            let jacketName: String = {
                if let raw = UserDefaults.standard.dictionary(forKey: AppController.KEY_JACKETS)?[deviceID] as? String,
                   let data = raw.data(using: .utf8),
                   let jacket = try? JSONDecoder().decode(Jacket.self, from: data) {
                    return jacket.name
                }
                return "the device"
            }()
            DispatchQueue.main.async {
                let alert = Alert(context: AppController.getContext())
                alert.confirmMessage = "OK"
                alert.create(
                    message: "Unable to pair with \"\(jacketName)\". The device reset its pairing information.\n\nTo fix:\n1. Open iOS Settings → Bluetooth\n2. Tap ⓘ next to \"\(jacketName)\" → \"Forget This Device\"\n3. Return here and tap \"Look for Mercury\" to re-pair.",
                    type: Alert.CONFIRM
                )
                alert.show()
            }
            eventsManager.trigger(eventName: Events.ON_SCAN_NOT_FOUND)
            return
        }

        pairingErrorCounts.removeValue(forKey: deviceID)
        pendingConnectionIDs.remove(deviceID)
        if AppController.getCurrentJacket()?.id == deviceID {
            scanTimeout()
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let deviceID = peripheral.identifier.uuidString
        let connectedAt = connectionStartTimes.removeValue(forKey: deviceID)
        let duration = connectedAt.map { Date().timeIntervalSince($0) } ?? 999
        print("Disconnected from peripheral:", deviceID.prefix(8),
              String(format: "(after %.1fs)", duration))

        // If we intentionally cancelled this peripheral to force a fresh reconnect,
        // now that the cancel is confirmed complete, proceed with the actual connect.
        if cancellingForReconnect.contains(deviceID) {
            cancellingForReconnect.remove(deviceID)
            print("Stale cancel complete — reconnecting \(deviceID.prefix(8))")
            connectByIDs([deviceID])
            return
        }

        guard connectedDeviceIDs.contains(deviceID) else { return }
        stopDeviceConnection(deviceID: deviceID)

        // If the vest dropped within 5 seconds of connecting it's almost certainly the
        // firmware variable-scope bug. Retry silently so the UI doesn't show the error
        // alert — the vest should reconnect cleanly on the next attempt.
        if duration < 5.0 {
            print("Quick disconnect — silent retry for \(deviceID.prefix(8))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard self.adapterIsEnabled else { return }
                self.connectAllRegistered()
            }
        } else {
            eventsManager.trigger(eventName: Events.ON_DEVICE_DISCONNECTED,
                                  information: [deviceID, true] as [AnyObject])
        }
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let deviceID = peripheral.identifier.uuidString
        if let error = error {
            print("Error discovering services:", error.localizedDescription)
            if AppController.getCurrentJacket()?.id == deviceID { scanTimeout() }
            return
        }
        guard let services = peripheral.services else { return }
        print("Discovered Services:", services)

        let uuids: [CBUUID] = [
            JacketGattAttributes.EXTERNAL_TEMPERATURE,
            JacketGattAttributes.ACTIVITY_LEVEL,
            JacketGattAttributes.SET_LOW_TEMP,
            JacketGattAttributes.SET_HIGH_TEMP,
            JacketGattAttributes.HIGH_TEMP_PT,
            JacketGattAttributes.LOW_TEMP_PT,
            JacketGattAttributes.MODE,
            JacketGattAttributes.POWER_LEVEL,
            JacketGattAttributes.POWER_OUTPUT,
            JacketGattAttributes.SAVE_NV_SETTINGS,
            JacketGattAttributes.MOTION_TEMP
        ]

        // Settle delay before characteristic discovery — the vest firmware has a variable-scope
        // bug where the registration variable is still being initialized during service discovery.
        // Calling discoverCharacteristics immediately causes the firmware to crash and drop the
        // connection. 800ms gives the firmware time to finish its own setup.
        let serviceRef = services[0]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard self.connectedDeviceIDs.contains(deviceID) else { return }
            peripheral.discoverCharacteristics(uuids, for: serviceRef)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let deviceID = peripheral.identifier.uuidString
        if let error = error {
            print("Error discovering characteristics:", error.localizedDescription)
            if AppController.getCurrentJacket()?.id == deviceID { scanTimeout() }
            return
        }
        guard let chars = service.characteristics else { return }
        print("Found \(chars.count) characteristics for \(deviceID.prefix(8))")

        characteristicsDic[deviceID] = [:]
        for char in chars {
            if char.uuid.uuidString == JacketGattAttributes.ACTIVITY_LEVEL.uuidString {
                peripheral.setNotifyValue(true, for: char)
            }
            characteristicsDic[deviceID]![char.uuid] = char
        }

        eventsManager.trigger(eventName: Events.ON_SERVICES_DICOVERED, information: deviceID)
        startReadTimer(deviceID: deviceID)
        readCharacteristics(deviceID: deviceID)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let deviceID = peripheral.identifier.uuidString
        if readCharacteristicDic[deviceID] == nil { readCharacteristicDic[deviceID] = [:] }

        var count = readCharacteristicDic[deviceID]![characteristic.uuid] ?? 0
        if count > 0 {
            count -= 1
            if count == 0 {
                readCharacteristicDic[deviceID]!.removeValue(forKey: characteristic.uuid)
            } else {
                readCharacteristicDic[deviceID]![characteristic.uuid] = count
            }
        }

        if let error = error {
            print("error didUpdateValueFor:", error._code)
            if error._code == 15 {
                stopDeviceConnection(deviceID: deviceID)
                eventsManager.trigger(eventName: Events.ON_DEVICE_DISCONNECTED,
                                      information: [deviceID, false] as [AnyObject])
            } else {
                readCharacteristic(uuid: characteristic.uuid, deviceID: deviceID)
            }
            return
        }

        if count == 0 {
            readValue(characteristic: characteristic, deviceID: deviceID)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic,
                    error: NSError?) {
        if let error = error {
            print("notify error:", error)
        } else {
            let deviceID = peripheral.identifier.uuidString
            print("NOTIFY:", JacketGattAttributes.getName(uuid: characteristic.uuid))
            readValue(characteristic: characteristic, deviceID: deviceID)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Write result!", JacketGattAttributes.getName(uuid: characteristic.uuid))
        let deviceID = peripheral.identifier.uuidString
        if readCharacteristicDic[deviceID] == nil { readCharacteristicDic[deviceID] = [:] }
        if writingCharacteristicDic[deviceID] == nil { writingCharacteristicDic[deviceID] = [:] }

        var count = readCharacteristicDic[deviceID]![characteristic.uuid] ?? 0
        if count > 0 {
            count -= 1
            if count == 0 {
                readCharacteristicDic[deviceID]!.removeValue(forKey: characteristic.uuid)
            } else {
                readCharacteristicDic[deviceID]![characteristic.uuid] = count
            }
        }

        if let error = error {
            print("write error:", error)
            if let value = writingCharacteristicDic[deviceID]![characteristic.uuid] {
                writingCharacteristicDic[deviceID]!.removeValue(forKey: characteristic.uuid)
                writeCharacteristic(uuid: characteristic.uuid, value: value, deviceID: deviceID)
            }
            return
        }

        if characteristic.uuid.uuidString == JacketGattAttributes.SAVE_NV_SETTINGS.uuidString {
            characteristicValuesDic[deviceID]?[JacketGattAttributes.POWER_LEVEL] = nil
        }
        print("Write succeeded!", JacketGattAttributes.getName(uuid: characteristic.uuid))
    }

    // MARK: - Read / Write

    private func readValue(characteristic: CBCharacteristic, deviceID: String) {
        guard let rxData = characteristic.value else { return }
        let count = rxData.count
        var rxByteArray = [UInt16](repeating: 0, count: count)
        (rxData as NSData).getBytes(&rxByteArray, length: count)
        let value = "\(rxByteArray[0])"

        if characteristicValuesDic[deviceID] == nil { characteristicValuesDic[deviceID] = [:] }
        guard characteristicValuesDic[deviceID]![characteristic.uuid] != value else { return }

        print(JacketGattAttributes.getName(uuid: characteristic.uuid), "=", value,
              "[\(deviceID.prefix(8))]")
        characteristicValuesDic[deviceID]![characteristic.uuid] = value
        // Payload: [deviceID, CBUUID, valueString] — listeners filter by deviceID if needed
        eventsManager.trigger(eventName: Events.ON_UPDATE_CHARACTERISTIC,
                              information: [deviceID, characteristic.uuid, value] as [AnyObject])
    }

    private func readCharacteristics(deviceID: String) {
        guard let chars = characteristicsDic[deviceID] else { return }
        checkVoiceControl()
        for (_, char) in chars {
            let readable = char.properties.rawValue & CBCharacteristicProperties.read.rawValue != 0
            if readable { readCharacteristic(uuid: char.uuid, deviceID: deviceID) }
        }
    }

    /// Triggers a read-all for the currently-selected jacket (called from StandByViewController).
    public func readCharacteristics() {
        readCharacteristics(deviceID: AppController.getCurrentJacket()?.id ?? "")
    }

    private func startReadTimer(deviceID: String) {
        readTimers[deviceID]?.invalidate()
        readTimers[deviceID] = Timer.scheduledTimer(withTimeInterval: TimeInterval(READ_TIME),
                                                    repeats: true) { [weak self] _ in
            self?.readCharacteristics(deviceID: deviceID)
        }
    }

    func writeCharacteristic(uuid: CBUUID, value: Int) {
        writeCharacteristic(uuid: uuid, value: value, deviceID: AppController.getCurrentJacket()?.id)
    }

    func writeCharacteristic(uuid: CBUUID, value: Int, deviceID: String?) {
        guard let id = deviceID,
              let peripheral = devices[id],
              let characteristic = characteristicsDic[id]?[uuid] else { return }

        if writingCharacteristicDic[id] == nil { writingCharacteristicDic[id] = [:] }
        if readCharacteristicDic[id] == nil { readCharacteristicDic[id] = [:] }
        writingCharacteristicDic[id]![uuid] = value
        readCharacteristicDic[id]![uuid] = (readCharacteristicDic[id]![uuid] ?? 0) + 1

        let bytes: Data
        if uuid.uuidString == JacketGattAttributes.SAVE_NV_SETTINGS.uuidString {
            var v: UInt8 = UInt8(value)
            bytes = Data(bytes: &v, count: MemoryLayout.size(ofValue: v))
        } else {
            var v: UInt16 = UInt16(truncatingIfNeeded: value)
            bytes = Data(bytes: &v, count: MemoryLayout.size(ofValue: v))
        }
        print("writeCharacteristic:", JacketGattAttributes.getName(uuid: uuid), "=", value)
        peripheral.writeValue(bytes, for: characteristic, type: .withResponse)
    }

    func readCharacteristic(uuid: CBUUID) {
        readCharacteristic(uuid: uuid, deviceID: AppController.getCurrentJacket()?.id)
    }

    func readCharacteristic(uuid: CBUUID, deviceID: String?) {
        guard let id = deviceID,
              let peripheral = devices[id],
              let characteristic = characteristicsDic[id]?[uuid] else { return }
        if readCharacteristicDic[id] == nil { readCharacteristicDic[id] = [:] }
        readCharacteristicDic[id]![uuid] = (readCharacteristicDic[id]![uuid] ?? 0) + 1
        peripheral.readValue(for: characteristic)
    }

    // MARK: - Scanning & Connecting

    /// Scans for a new (unregistered) device when called with no argument.
    /// Pass an existing jacket ID to reconnect a single known device (legacy path).
    func scanDevice(id: String? = nil) {
        if let deviceID = id {
            guard !connectedDeviceIDs.contains(deviceID) else { return }
            pendingConnectionIDs.insert(deviceID)
            startScanTimer()
            if let uuid = UUID(uuidString: deviceID) {
                let found = manager.retrievePeripherals(withIdentifiers: [uuid])
                if let peripheral = found.first {
                    pendingConnectionIDs.remove(deviceID)
                    connect(peripheral: peripheral)
                    return
                }
            }
            if !scanning {
                scanning = true
                manager.delegate = self
                manager.scanForPeripherals(withServices: nil, options: nil)
            }
        } else {
            guard !scanningForNew else { return }
            scanningForNew = true
            startScanTimer()
            if !scanning {
                scanning = true
                manager.delegate = self
                manager.scanForPeripherals(withServices: nil, options: nil)
            }
        }
    }

    /// Connects to ALL registered jackets that are not yet connected.
    /// Call this from DisconnectedViewController / app startup instead of scanDevice(id:).
    public func connectAllRegistered() {
        guard let saved = UserDefaults.standard.dictionary(forKey: AppController.KEY_JACKETS)
                as? [String: String] else { return }

        let unconnectedIDs = Set(saved.keys)
            .subtracting(connectedDeviceIDs)
            .subtracting(pendingConnectionIDs)
            .subtracting(cancellingForReconnect)
        guard !unconnectedIDs.isEmpty else { return }

        startScanTimer()

        // For devices that appear stale (connected at iOS level but not in our app state),
        // cancel first and reconnect once didDisconnectPeripheral confirms the cancel completed.
        // Connecting immediately after cancel is a race condition that drops the second device.
        let staleConnected = manager.retrieveConnectedPeripherals(withServices: [JacketGattAttributes.serviceCBUUID])
        var staleIDs = Set<String>()
        for p in staleConnected where unconnectedIDs.contains(p.identifier.uuidString) {
            staleIDs.insert(p.identifier.uuidString)
            cancellingForReconnect.insert(p.identifier.uuidString)
            manager.cancelPeripheralConnection(p)
        }

        // Connect all non-stale unconnected devices immediately
        connectByIDs(Set(unconnectedIDs).subtracting(staleIDs))
    }

    /// Looks up cached peripherals for the given IDs and connects; starts a scan for any not cached.
    private func connectByIDs(_ ids: Set<String>) {
        guard !ids.isEmpty else { return }
        let uuids = ids.compactMap { UUID(uuidString: $0) }
        let cached = manager.retrievePeripherals(withIdentifiers: uuids)
        var foundIDs = Set<String>()
        for peripheral in cached {
            let pid = peripheral.identifier.uuidString
            foundIDs.insert(pid)
            connect(peripheral: peripheral)
        }
        let missing = ids.subtracting(foundIDs)
        if !missing.isEmpty {
            pendingConnectionIDs.formUnion(missing)
            if !scanning {
                scanning = true
                manager.delegate = self
                manager.scanForPeripherals(withServices: nil, options: nil)
            }
        }
    }

    public func connect(peripheral: CBPeripheral) {
        let deviceID = peripheral.identifier.uuidString
        devices[deviceID] = peripheral
        peripheral.delegate = self
        eventsManager.trigger(eventName: Events.ON_DEVICE_CONNECTING, information: deviceID)
        manager.connect(peripheral, options: nil)
    }

    func stopScan() {
        scanning = false
        scanningForNew = false
        pendingConnectionIDs.removeAll()
        cancellingForReconnect.removeAll()
        manager?.stopScan()
        stopScanTimer()
    }

    /// Stops ALL active connections and clears all state.
    public func stopConnection() {
        for deviceID in Array(connectedDeviceIDs) { stopDeviceConnection(deviceID: deviceID) }
        for deviceID in Array(pendingConnectionIDs) {
            if let p = devices[deviceID] { manager?.cancelPeripheralConnection(p) }
            devices.removeValue(forKey: deviceID)
        }
        pendingConnectionIDs.removeAll()
        stopScan()
        amazonQueue?.cancel()
        amazonQueue = nil
    }

    /// Stops the connection for a single specific device (e.g. explicit user disconnect).
    public func stopConnection(deviceID: String) {
        let wasConnected = connectedDeviceIDs.contains(deviceID)
        stopDeviceConnection(deviceID: deviceID)
        pendingConnectionIDs.remove(deviceID)
        if connectedDeviceIDs.isEmpty && pendingConnectionIDs.isEmpty { stopScan() }
        // Fire disconnect event so the UI (DashBoardViewController → DisconnectedViewController)
        // knows to show the reconnect screen. stopDeviceConnection removes the device from
        // connectedDeviceIDs before cancelPeripheralConnection fires didDisconnectPeripheral,
        // so didDisconnectPeripheral's guard exits early and won't fire this event itself.
        if wasConnected {
            eventsManager.trigger(eventName: Events.ON_DEVICE_DISCONNECTED,
                                  information: [deviceID, true] as [AnyObject])
        }
    }

    private func stopDeviceConnection(deviceID: String) {
        connectedDeviceIDs.remove(deviceID)
        connectionStartTimes.removeValue(forKey: deviceID)
        characteristicValuesDic.removeValue(forKey: deviceID)
        readCharacteristicDic.removeValue(forKey: deviceID)
        writingCharacteristicDic.removeValue(forKey: deviceID)
        readTimers[deviceID]?.invalidate()
        readTimers.removeValue(forKey: deviceID)
        characteristicsDic.removeValue(forKey: deviceID)
        if let peripheral = devices[deviceID] {
            peripheral.delegate = nil
            manager?.cancelPeripheralConnection(peripheral)
            devices.removeValue(forKey: deviceID)
        }
    }

    public func destroy() {
        print("DESTROY")
        eventsManager = EventManager()
        stopConnection()
        scanning = false
        scanningForNew = false
    }

    // MARK: - Scan Timer

    private func startScanTimer() {
        stopScanTimer()
        scanTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(SCAN_TIME),
                                        repeats: false) { [weak self] _ in
            self?.scanTimeout()
        }
    }

    private func stopScanTimer() {
        scanTimer?.invalidate()
        scanTimer = nil
    }

    private func scanTimeout() {
        print("Scan timeout")
        let wasNewScan = scanningForNew
        let currentID = AppController.getCurrentJacket()?.id
        stopScan()
        // Always fire when scanning for a new device (Add new jacket flow).
        // Also fire when the current jacket itself isn't connected yet.
        if wasNewScan || (currentID != nil && !connectedDeviceIDs.contains(currentID!)) {
            eventsManager.trigger(eventName: Events.ON_SCAN_NOT_FOUND)
        }
    }

    // MARK: - Event listeners

    public func listenTo(id: String, eventName: String, action: @escaping (() -> ())) {
        eventsManager.listenTo(id: id, eventName: eventName, action: action)
    }

    public func listenTo(id: String, eventName: String, action: @escaping ((Any?) -> ())) {
        eventsManager.listenTo(id: id, eventName: eventName, action: action)
    }

    public func removeListeners(id: String, eventNameToRemoveOrNil: String?) {
        eventsManager.removeListeners(id: id, eventNameToRemoveOrNil: eventNameToRemoveOrNil)
    }

    // MARK: - Alexa / Voice

    private func checkVoiceControl() {
        guard let jacket = AppController.getCurrentJacket() else { return }
        let voiceControl: Bool = jacket.getSetting(key: Jacket.VOICE_CONTROL)
        if voiceControl && amazon_email == nil {
            AIMobileLib.getProfile(self)
        } else if amazon_email != nil && !voiceControl {
            amazon_email = nil
        } else if amazon_email != nil && voiceControl {
            loadAlexaStatus()
        }
    }

    private func loadAlexaStatus() {
        guard amazonQueue == nil else { return }
        let url = String(format: ALEXA_URL, amazon_email!)
        print("URL_GET_STATUS", url)
        amazonQueue = Alamofire.request(url, method: .get)
            .responseJSON { response in
                self.amazonQueue = nil
                switch response.result {
                case .success:
                    let statusJson = JSON(response.data!)["jacketStatus"]
                    let status: Int = statusJson.exists() ? statusJson.intValue : -1
                    print("JACKETSTATUS", status)
                    if status > -1 {
                        self.writeCharacteristic(uuid: JacketGattAttributes.MODE, value: status)
                        self.writeCharacteristic(uuid: JacketGattAttributes.MODE, value: status)
                    }
                case .failure:
                    print("jacketStatus error")
                }
            }
    }

    func requestDidSucceed(_ apiResult: APIResult!) {
        DispatchQueue.main.async {
            self.amazon_email = (apiResult?.result as? [AnyHashable: Any])?["email"] as? String
            print("AMAZON_RESULT", apiResult?.result as Any)
            if self.amazon_email != nil { self.loadAlexaStatus() }
        }
    }

    func requestDidFail(_ errorResponse: APIError!) {
        print("Error:", errorResponse.error.message ?? "nil")
    }
}
