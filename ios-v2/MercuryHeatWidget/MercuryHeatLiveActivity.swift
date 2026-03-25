//
//  MercuryHeatLiveActivity.swift
//  MercuryHeatWidget — Lock Screen + Dynamic Island UI
//

import ActivityKit
import Charts
import SwiftUI
import WidgetKit

struct MercuryHeatLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MercuryHeatAttributes.self) { context in
            MercuryHeatLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.jacketName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        Text(context.state.modeTitle)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Text("Heat \(formatPower(context.state.powerLevel0to10))")
                            .font(.title3.weight(.bold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 6)
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Label {
                            Text(context.state.jacketTempText)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        } icon: {
                            Image(systemName: "thermometer.medium")
                        }
                        Label {
                            Text(context.state.ambientTempText)
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        } icon: {
                            Image(systemName: "cloud.sun")
                        }
                        Label {
                            Text("\(context.state.batteryPercent)%")
                                .font(.caption2)
                        } icon: {
                            Image(systemName: "battery.100")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.leading, 4)
                    .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    MercuryHeatSparkline(samples: context.state.sparklinePower)
                        .frame(height: 44)
                }
            } compactLeading: {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                Text(formatPowerShort(context.state.powerLevel0to10))
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
            }
        }
    }
}

// MARK: - Lock Screen

private struct MercuryHeatLockScreenView: View {
    let context: ActivityViewContext<MercuryHeatAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Text(context.attributes.jacketName)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(context.state.modeTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("Heat")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatPower(context.state.powerLevel0to10))
                    .font(.title2.weight(.bold))
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Garment \(context.state.jacketTempText)")
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Outside \(context.state.ambientTempText)")
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Battery \(context.state.batteryPercent)%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            MercuryHeatSparkline(samples: context.state.sparklinePower)
                .frame(height: 56)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

// MARK: - Sparkline

private struct MercuryHeatSparkline: View {
    let samples: [Float]

    var body: some View {
        Group {
            if samples.count >= 2 {
                Chart(Array(samples.enumerated()), id: \.offset) { item in
                    LineMark(
                        x: .value("i", item.offset),
                        y: .value("p", Double(item.element))
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(.orange)
                    AreaMark(
                        x: .value("i", item.offset),
                        y: .value("p", Double(item.element))
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.35), Color.orange.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartYScale(domain: 0...10)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            } else {
                Text("Collecting heat data…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }
}

// MARK: - Formatting

private func formatPower(_ v: Float) -> String {
    String(format: "%.1f / 10", min(10, max(0, v)))
}

private func formatPowerShort(_ v: Float) -> String {
    String(format: "%.0f", min(10, max(0, v)))
}
