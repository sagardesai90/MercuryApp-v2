import Foundation

class SessionLogger {

    static let shared = SessionLogger()
    private init() {}

    private let storageKey = "mj_session_history_v1"
    private var logTimer: Timer?
    private(set) var currentSession: Session?
    private(set) var ambientTempCelsius: Float = 0

    // Called once from AppController.setup() after BluetoothController is created.
    func start() {
        let bt = BluetoothController.getInstance()
        bt.listenTo(id: "SessionLogger", eventName: BluetoothController.Events.ON_DEVICE_CONNECTED) { (param) in
            // Only log sessions for the currently-selected jacket
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

    // Updated by DashBoardViewController whenever weather or jacket temp changes.
    func updateAmbientTemp(celsius: Float) {
        ambientTempCelsius = celsius
    }

    // MARK: - Session lifecycle

    private func beginSession() {
        closeSession()
        let name = AppController.getCurrentJacket()?.name ?? "Mercury Jacket"
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
        persist(session: session)
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

    /// Returns the current session with an extra live data point appended for
    /// real-time display. The live point is NOT saved to UserDefaults.
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

    // MARK: - Persistence

    private func persist(session: Session) {
        var all = allSessions()
        all.insert(session, at: 0)
        all = Array(all.prefix(30))
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func allSessions() -> [Session] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let sessions = try? JSONDecoder().decode([Session].self, from: data) else {
            return []
        }
        return sessions
    }
}
