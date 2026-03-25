//
//  MercuryHeatActivityAttributes.swift
//  Shared between Mercury Jacket and MercuryHeatWidget extension.
//

import ActivityKit
import Foundation

struct MercuryHeatAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var powerLevel0to10: Float
        public var modeTitle: String
        public var jacketTempText: String
        public var ambientTempText: String
        public var batteryPercent: Int
        /// Normalized 0–10 power samples for the sparkline (oldest → newest).
        public var sparklinePower: [Float]

        public init(
            powerLevel0to10: Float,
            modeTitle: String,
            jacketTempText: String,
            ambientTempText: String,
            batteryPercent: Int,
            sparklinePower: [Float]
        ) {
            self.powerLevel0to10 = powerLevel0to10
            self.modeTitle = modeTitle
            self.jacketTempText = jacketTempText
            self.ambientTempText = ambientTempText
            self.batteryPercent = batteryPercent
            self.sparklinePower = sparklinePower
        }
    }

    public var jacketName: String
}
