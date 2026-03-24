import Foundation

struct Session: Codable {
    let id: String
    let jacketName: String
    let startDate: Date
    var endDate: Date?
    var dataPoints: [SessionDataPoint]

    var isActive: Bool { endDate == nil }

    var duration: TimeInterval {
        (endDate ?? Date()).timeIntervalSince(startDate)
    }

    var averagePower0to10: Float {
        guard !dataPoints.isEmpty else { return 0 }
        return dataPoints.map { $0.powerLevel0to10 }.reduce(0, +) / Float(dataPoints.count)
    }

    var averageJacketTempCelsius: Float {
        guard !dataPoints.isEmpty else { return 0 }
        return dataPoints.map { $0.jacketTempCelsius }.reduce(0, +) / Float(dataPoints.count)
    }

    var averageAmbientTempCelsius: Float {
        guard !dataPoints.isEmpty else { return 0 }
        return dataPoints.map { $0.ambientTempCelsius }.reduce(0, +) / Float(dataPoints.count)
    }

    var tempDeltaCelsius: Float {
        averageJacketTempCelsius - averageAmbientTempCelsius
    }

    // Rough estimate: average power fraction × hours × 45W rated max
    var estimatedEnergyWh: Float {
        guard duration > 0, !dataPoints.isEmpty else { return 0 }
        let hours = Float(duration) / 3600.0
        return (averagePower0to10 / 10.0) * hours * 45.0
    }
}
