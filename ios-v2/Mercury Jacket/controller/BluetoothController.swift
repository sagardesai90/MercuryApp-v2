import UIKit
import CoreBluetooth
import Combine

class BluetoothController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, AlexaServiceDelegate {

    private let TAG: String = "BluetoothController"
    private func isMercuryDevice(name: String) -> Bool {
        return name.lowercased().hasPrefix("mercury")
    }
    private let SCAN_TIME: Int = 20
    private let READ_TIME: Int = 3

    private static var instance: BluetoothController?

    // MARK: - Combine publishers (modern alternative to EventManager)

    let deviceConnectedPublisher = PassthroughSubject<String, Never>()
    let deviceDisconnectedPublisher = PassthroughSubject<(deviceID: String, tryReconnect: Bool), Never>()
    let characteristicUpdatedPublisher = PassthroughSubject<(deviceID: String, uuid: CBUUID, value: String), Never>()
    let servicesDiscoveredPublisher = PassthroughSubject<String, Never>()
    let scanFoundPublisher = PassthroughSubject<CBPeripheral, Never>()
    let scanNotFoundPublisher = PassthroughSubject<Void, Never>()
    let adapterStatePublisher = PassthroughSubject<Bool, Never>()
    let deviceConnectingPublisher = PassthroughSubject<String, Never>()

    // Legacy string-based event names (kept for backward compatibility)
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

    private var devices: [String: CBPeripheral] = [:]
    private var characteristicsDic: [String: [CBUUID: CBCharacteristic]] = [:]
    private var characteristicValuesDic: [String: [CBUUID: String]] = [:]
    private var readCharacteristicDic: [String: [CBUUID: Int]] = [:]
    private var writingCharacteristicDic: [String: [CBUUID: Int]] = [:]
    private var readTimers: [String: Timer] = [:]

    private var connectedDeviceIDs: Set<String> = []
    private var pendingConnectionIDs: Set<String> = []
    private var cancellingForReconnect: Set<String> = []
    private var pairingErrorCounts: [String: Int] = [:]
    private let MAX_PAIRING_RETRIES = 3
    private var connectionStartTimes: [String: Date] = [:]
    private var scanning: Bool = false
    private var scanningForNew: Bool = false

    private var scanTimer: Timer?
    private var adapterAlert: Alert!

    private let alexaService: AlexaService

    public var adapterIsEnabled: Bool = false

    // MARK: - Lifecycle

    init(alexaService: AlexaService) {
        self.alexaService = alexaService
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

    public func getValue(uuid: CBUUID) -> Int {
        return getValue(uuid: uuid, deviceID: AppController.getCurrentJacket()?.id)
    }

    public func getValue(uuid: CBUUID, deviceID: String?) -> Int {
        guard let id = deviceID else { return 0 }
        return Int(characteristicValuesDic[id]?[uuid] ?? "0") ?? 0
    }

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
            self.adapterStatePublisher.send(true)
            if adapterAlert != nil {
                adapterAlert.dismiss()
                adapterAlert = nil
            }
        case .poweredOff:
            print("Bluetooth is Off.")
            self.adapterIsEnabled = false
            self.eventsManager.trigger(eventName: Events.ON_ADAPTER_DISCONNECT)
            self.adapterStatePublisher.send(false)
            for deviceID in Array(connectedDeviceIDs) {
                stopDeviceConnection(deviceID: deviceID)
                eventsManager.trigger(eventName: Events.ON_DEVICE_DISCONNECTED,
                                      information: [deviceID, true] as [AnyObject])
                deviceDisconnectedPublisher.send((deviceID: deviceID, tryReconnect: true))
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

        if scanningForNew {
            let name = peripheral.name ?? ""
            let advertisedServiceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
            let looksLikeMercury = isMercuryDevice(name: name)
                || advertisedServiceUUIDs.contains(JacketGattAttributes.serviceCBUUID)
            if looksLikeMercury {
                let saved = UserDefaults.standard.dictionary(forKey: BluetoothController.KEY_JACKETS) as? [String: String]
                if saved == nil || saved![peripheralID] == nil {
                    print("DEVICE FOUND", "Name: \"\(name.isEmpty ? "<no name>" : name)\", Identifier: \(peripheralID)")
                    scanningForNew = false
                    if pendingConnectionIDs.isEmpty {
                        manager.stopScan()
                        scanning = false
                        stopScanTimer()
                    }
                    eventsManager.trigger(eventName: Events.ON_SCAN_FOUND, information: peripheral)
                    scanFoundPublisher.send(peripheral)
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
        pairingErrorCounts.removeValue(forKey: deviceID)
        if characteristicValuesDic[deviceID] == nil { characteristicValuesDic[deviceID] = [:] }

        eventsManager.trigger(eventName: Events.ON_DEVICE_CONNECTED, information: deviceID)
        deviceConnectedPublisher.send(deviceID)
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
            print("Pairing retries exhausted for \(deviceID.prefix(8)) — prompting user to forget device")
            pairingErrorCounts.removeValue(forKey: deviceID)
            pendingConnectionIDs.remove(deviceID)
            let jacketName: String = {
                if let raw = UserDefaults.standard.dictionary(forKey: "jackets")?[deviceID] as? String,
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
            scanNotFoundPublisher.send()
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

        if cancellingForReconnect.contains(deviceID) {
            cancellingForReconnect.remove(deviceID)
            print("Stale cancel complete — reconnecting \(deviceID.prefix(8))")
            connectByIDs([deviceID])
            return
        }

        guard connectedDeviceIDs.contains(deviceID) else { return }
        stopDeviceConnection(deviceID: deviceID)

        if duration < 5.0 {
            print("Quick disconnect — silent retry for \(deviceID.prefix(8))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard self.adapterIsEnabled else { return }
                self.connectAllRegistered()
            }
        } else {
            eventsManager.trigger(eventName: Events.ON_DEVICE_DISCONNECTED,
                                  information: [deviceID, true] as [AnyObject])
            deviceDisconnectedPublisher.send((deviceID: deviceID, tryReconnect: true))
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
            JacketGattAttributes.MOTION_TEMP,
            JacketGattAttributes.BATTERY_LEVEL
        ]

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
        servicesDiscoveredPublisher.send(deviceID)
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
                deviceDisconnectedPublisher.send((deviceID: deviceID, tryReconnect: false))
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
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
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
        eventsManager.trigger(eventName: Events.ON_UPDATE_CHARACTERISTIC,
                              information: [deviceID, characteristic.uuid, value] as [AnyObject])
        characteristicUpdatedPublisher.send((deviceID: deviceID, uuid: characteristic.uuid, value: value))
    }

    private func readCharacteristics(deviceID: String) {
        guard let chars = characteristicsDic[deviceID] else { return }
        checkVoiceControl()
        for (_, char) in chars {
            let readable = char.properties.rawValue & CBCharacteristicProperties.read.rawValue != 0
            if readable { readCharacteristic(uuid: char.uuid, deviceID: deviceID) }
        }
    }

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

    public func connectAllRegistered() {
        guard let saved = UserDefaults.standard.dictionary(forKey: "jackets")
                as? [String: String] else { return }

        let unconnectedIDs = Set(saved.keys)
            .subtracting(connectedDeviceIDs)
            .subtracting(pendingConnectionIDs)
            .subtracting(cancellingForReconnect)
        guard !unconnectedIDs.isEmpty else { return }

        startScanTimer()

        let staleConnected = manager.retrieveConnectedPeripherals(withServices: [JacketGattAttributes.serviceCBUUID])
        var staleIDs = Set<String>()
        for p in staleConnected where unconnectedIDs.contains(p.identifier.uuidString) {
            staleIDs.insert(p.identifier.uuidString)
            cancellingForReconnect.insert(p.identifier.uuidString)
            manager.cancelPeripheralConnection(p)
        }

        connectByIDs(Set(unconnectedIDs).subtracting(staleIDs))
    }

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
        deviceConnectingPublisher.send(deviceID)
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

    public func stopConnection() {
        for deviceID in Array(connectedDeviceIDs) { stopDeviceConnection(deviceID: deviceID) }
        for deviceID in Array(pendingConnectionIDs) {
            if let p = devices[deviceID] { manager?.cancelPeripheralConnection(p) }
            devices.removeValue(forKey: deviceID)
        }
        pendingConnectionIDs.removeAll()
        stopScan()
        alexaService.reset()
    }

    public func stopConnection(deviceID: String) {
        let wasConnected = connectedDeviceIDs.contains(deviceID)
        stopDeviceConnection(deviceID: deviceID)
        pendingConnectionIDs.remove(deviceID)
        if connectedDeviceIDs.isEmpty && pendingConnectionIDs.isEmpty { stopScan() }
        if wasConnected {
            eventsManager.trigger(eventName: Events.ON_DEVICE_DISCONNECTED,
                                  information: [deviceID, true] as [AnyObject])
            deviceDisconnectedPublisher.send((deviceID: deviceID, tryReconnect: true))
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
        if wasNewScan || (currentID != nil && !connectedDeviceIDs.contains(currentID!)) {
            eventsManager.trigger(eventName: Events.ON_SCAN_NOT_FOUND)
            scanNotFoundPublisher.send()
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

    // MARK: - Alexa / Voice (delegated to AlexaService)

    private func checkVoiceControl() {
        guard let jacket = AppController.getCurrentJacket() else { return }
        let voiceControl: Bool = jacket.getSetting(key: Jacket.VOICE_CONTROL)
        alexaService.checkVoiceControl(voiceEnabled: voiceControl)
    }

    // MARK: - AlexaServiceDelegate

    func alexaService(_ service: AlexaService, didReceiveMode mode: Int) {
        writeCharacteristic(uuid: JacketGattAttributes.MODE, value: mode)
        writeCharacteristic(uuid: JacketGattAttributes.MODE, value: mode)
    }

    // MARK: - Legacy key for scan discovery
    // Used by centralManager(_:didDiscover:) to check saved jackets
    private static let KEY_JACKETS = "jackets"
}
