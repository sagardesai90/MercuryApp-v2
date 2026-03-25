import Foundation

class SessionLogger {

    static var shared = SessionLogger()

    private let sessionStore: SessionStore
    private var logTimer: Timer?
    private(set) var currentSession: Session?
    private(set) var ambientTempCelsius: Float = 0

    init(sessionStore: SessionStore = UserDefaultsSessionStore()) {
        self.sessionStore = sessionStore
    }

    func start() {
        let bt = BluetoothController.getInstance()
        bt.listenTo(id: "SessionLogger", eventName: BluetoothController.Events.ON_DEVICE_CONNECTED) { (param) in
            guard let deviceID = param as? String,
                  deviceID == AppController.getCurrentJacket()?.id else { return }
            self.beginSession()
        }
        bt.listenTo(id: "SessionLogger", eventName: BluetoothController.Events.ON_DEVICE_DISCONNECTED) { (param) in
            guard let arr = param as? [AnyObject], let deviceID = arr[0] as? String,
                  deviceID == AppController.getCurrentJacket()?.id else { return }
            self.closeSession()
        }
        if bt.isConnected() {
            beginSession()
        }
    }

    func updateAmbientTemp(celsius: Float) {
        ambientTempCelsius = celsius
    }

    // MARK: - Session lifecycle

    private func beginSession() {
        closeSession()
        let name = AppController.getCurrentJacket()?.name ?? "Mercury App"
        currentSession = Session(
            id: UUID().uuidString,
            jacketName: name,
            startDate: Date(),
            endDate: nil,
            dataPoints: []
        )
        logDataPoint()
        logTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.logDataPoint()
        }
    }

    private func closeSession() {
        logTimer?.invalidate()
        logTimer = nil
        guard var session = currentSession else { return }
        if session.dataPoints.isEmpty {
            currentSession = nil
            return
        }
        session.endDate = Date()
        currentSession = nil
        sessionStore.persist(session: session)
    }

    private func logDataPoint() {
        guard currentSession != nil else { return }
        let bt = BluetoothController.getInstance()
        let rawTemp = bt.getValue(uuid: JacketGattAttributes.EXTERNAL_TEMPERATURE)
        let powerOut = bt.getValue(uuid: JacketGattAttributes.POWER_OUTPUT)
        let point = SessionDataPoint(
            timestamp: Date(),
            jacketTempCelsius: Float(rawTemp) / 10.0,
            ambientTempCelsius: ambientTempCelsius,
            powerLevel: bt.getValue(uuid: JacketGattAttributes.POWER_LEVEL),
            powerOutputRaw: powerOut > 0 ? powerOut : nil,
            activityLevel: bt.getValue(uuid: JacketGattAttributes.ACTIVITY_LEVEL),
            mode: bt.getValue(uuid: JacketGattAttributes.MODE)
        )
        currentSession?.dataPoints.append(point)
    }

    func currentSessionForDisplay() -> Session? {
        guard var session = currentSession else { return nil }
        let bt = BluetoothController.getInstance()
        guard bt.isConnected() else { return session }
        let rawTemp  = bt.getValue(uuid: JacketGattAttributes.EXTERNAL_TEMPERATURE)
        let powerOut = bt.getValue(uuid: JacketGattAttributes.POWER_OUTPUT)
        let livePoint = SessionDataPoint(
            timestamp: Date(),
            jacketTempCelsius: Float(rawTemp) / 10.0,
            ambientTempCelsius: ambientTempCelsius,
            powerLevel: bt.getValue(uuid: JacketGattAttributes.POWER_LEVEL),
            powerOutputRaw: powerOut > 0 ? powerOut : nil,
            activityLevel: bt.getValue(uuid: JacketGattAttributes.ACTIVITY_LEVEL),
            mode: bt.getValue(uuid: JacketGattAttributes.MODE)
        )
        session.dataPoints.append(livePoint)
        return session
    }

    // MARK: - Read

    func allSessions() -> [Session] {
        sessionStore.allSessions()
    }
}
