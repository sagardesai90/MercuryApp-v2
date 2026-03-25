//
//  HeatLiveActivityManager.swift
//  Mercury Jacket — starts/updates Live Activity from BLE state (iOS 16.2+).
//  ActivityContent / async Activity APIs require 16.2 (not 16.1).
//

@preconcurrency import ActivityKit
import Foundation

@available(iOS 16.2, *)
@MainActor
final class HeatLiveActivityManager {
    static let shared = HeatLiveActivityManager()

    private var activity: Activity<MercuryHeatAttributes>?
    private var sparkline: [Float] = []
    private let maxSamples = 32
    private var lastUpdate: Date = .distantPast
    private let minUpdateInterval: TimeInterval = 1.0

    func start(jacketName: String) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if activity != nil { return }

        let attributes = MercuryHeatAttributes(jacketName: jacketName)
        let state = Self.makeContentState(
            power0to10: 0,
            modeTitle: "—",
            jacketTempText: "—",
            ambientTempText: "—",
            batteryPercent: 0,
            sparkline: []
        )
        do {
            activity = try Self.requestActivity(attributes: attributes, initialState: state)
        } catch {
            activity = nil
        }
    }

    func update(
        powerLevel0to10: Float,
        modeTitle: String,
        jacketTempText: String,
        ambientTempText: String,
        batteryPercent: Int
    ) async {
        let p = min(10, max(0, powerLevel0to10))
        sparkline.append(p)
        if sparkline.count > maxSamples {
            sparkline.removeFirst(sparkline.count - maxSamples)
        }

        let now = Date()
        if now.timeIntervalSince(lastUpdate) < minUpdateInterval && activity != nil {
            return
        }
        lastUpdate = now

        guard let activity else { return }
        let state = Self.makeContentState(
            power0to10: p,
            modeTitle: modeTitle,
            jacketTempText: jacketTempText,
            ambientTempText: ambientTempText,
            batteryPercent: min(100, max(0, batteryPercent)),
            sparkline: sparkline
        )
        let content = ActivityContent(state: state, staleDate: nil)
        await activity.update(content)
    }

    func flush(
        powerLevel0to10: Float,
        modeTitle: String,
        jacketTempText: String,
        ambientTempText: String,
        batteryPercent: Int
    ) async {
        lastUpdate = .distantPast
        await update(
            powerLevel0to10: powerLevel0to10,
            modeTitle: modeTitle,
            jacketTempText: jacketTempText,
            ambientTempText: ambientTempText,
            batteryPercent: batteryPercent
        )
    }

    /// Throttled updates from BLE (used while heating session is active).
    func updateFromBluetoothState() async {
        let p = Self.payloadFromBluetooth()
        await update(
            powerLevel0to10: p.power,
            modeTitle: p.modeTitle,
            jacketTempText: p.jacketTempText,
            ambientTempText: p.ambientTempText,
            batteryPercent: p.batteryPercent
        )
    }

    /// Forces an immediate Live Activity refresh (e.g. after °C / °F change).
    func refreshFromBluetoothState() async {
        let p = Self.payloadFromBluetooth()
        await flush(
            powerLevel0to10: p.power,
            modeTitle: p.modeTitle,
            jacketTempText: p.jacketTempText,
            ambientTempText: p.ambientTempText,
            batteryPercent: p.batteryPercent
        )
    }

    private struct LiveActivityPayload {
        let power: Float
        let modeTitle: String
        let jacketTempText: String
        let ambientTempText: String
        let batteryPercent: Int
    }

    private static func payloadFromBluetooth() -> LiveActivityPayload {
        let bt = BluetoothController.getInstance()
        let power = Float(bt.getValue(uuid: JacketGattAttributes.POWER_LEVEL)) / 1000.0
        let rawExt = bt.getValue(uuid: JacketGattAttributes.EXTERNAL_TEMPERATURE)
        let jacketTemp: String
        if rawExt != 0 {
            let celsius = Float(rawExt) / 10.0
            jacketTemp = formatTemperature(celsius: celsius)
        } else {
            jacketTemp = "—"
        }
        let ambientC = SessionLogger.shared.ambientTempCelsius
        let ambientText: String
        if ambientC != 0 {
            ambientText = formatTemperature(celsius: ambientC)
        } else {
            ambientText = "—"
        }
        let battery = bt.getValue(uuid: JacketGattAttributes.BATTERY_LEVEL)
        let modeVal = bt.getValue(uuid: JacketGattAttributes.MODE)
        let mode = modeVal == JacketGattAttributes.SMART_MODE ? "Smart" : "Manual"
        return LiveActivityPayload(
            power: power,
            modeTitle: mode,
            jacketTempText: jacketTemp,
            ambientTempText: ambientText,
            batteryPercent: min(100, max(0, battery))
        )
    }

    private static func formatTemperature(celsius: Float) -> String {
        if AppController.getTemperatureMeasure() == AppController.FAHRENHEIT {
            let f = AppController.celsiusToFahrenheit(value: celsius)
            return String(format: "%.0f°F", f)
        }
        return String(format: "%.0f°C", celsius)
    }

    func end() async {
        guard let activity else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
        self.activity = nil
        sparkline.removeAll()
    }

    @available(iOS 16.2, *)
    private static func requestActivity(
        attributes: MercuryHeatAttributes,
        initialState: MercuryHeatAttributes.ContentState
    ) throws -> Activity<MercuryHeatAttributes> {
        try Activity.request(
            attributes: attributes,
            content: ActivityContent(state: initialState, staleDate: nil),
            pushType: nil
        )
    }

    private static func makeContentState(
        power0to10: Float,
        modeTitle: String,
        jacketTempText: String,
        ambientTempText: String,
        batteryPercent: Int,
        sparkline: [Float]
    ) -> MercuryHeatAttributes.ContentState {
        MercuryHeatAttributes.ContentState(
            powerLevel0to10: power0to10,
            modeTitle: modeTitle,
            jacketTempText: jacketTempText,
            ambientTempText: ambientTempText,
            batteryPercent: batteryPercent,
            sparklinePower: sparkline
        )
    }
}
