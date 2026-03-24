import Foundation

struct SessionDataPoint: Codable {
    let timestamp: Date
    let jacketTempCelsius: Float
    let ambientTempCelsius: Float
    let powerLevel: Int       // 0–10000
    let powerOutputRaw: Int?  // raw BLE value from POWER_OUTPUT characteristic
    let activityLevel: Int    // 0 = static, 1 = moving
    let mode: Int

    var powerLevel0to10: Float {
        Float(powerLevel) / 1000.0
    }

    // Power output in watts. The characteristic appears to report tenths-of-watts
    // (e.g. raw=80 → 8.0W). Adjust divisor once confirmed with hardware.
    var powerOutputWatts: Float? {
        guard let raw = powerOutputRaw, raw > 0 else { return nil }
        return Float(raw) / 10.0
    }
}
