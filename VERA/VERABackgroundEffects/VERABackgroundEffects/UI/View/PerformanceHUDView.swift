//
//  Created by Vonage on 11/5/26.
//

import SwiftUI

/// Compact monospaced HUD showing the live performance counters from
/// ``TransformPerformanceTracker``.
///
/// Designed to sit on top of the camera preview or alongside the other waiting-room
/// buttons. Only renders the rows that have useful data — when the Vonage provider
/// is active the transform/vision rows show "—" since we can't instrument their
/// internal pipeline.
public struct PerformanceHUDView: View {

    @ObservedObject private var tracker: TransformPerformanceTracker

    public init(tracker: TransformPerformanceTracker = .shared) {
        self.tracker = tracker
    }

    public var body: some View {
        if tracker.isVisible {
            hud
        } else {
            EmptyView()
        }
    }

    private var hud: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(tracker.providerLabel)
                    .foregroundStyle(.white)
                Text("/")
                    .foregroundStyle(.white.opacity(0.4))
                Text(tracker.engineLabel)
                    .foregroundStyle(.white)
            }
            .font(.system(.caption2, design: .monospaced).bold())

            row(label: "res", value: tracker.resolutionLabel)
            row(label: "fps", value: String(format: "%.0f", tracker.framesPerSecond))
            row(label: "in", value: ms(tracker.copyInMs))
            row(label: "infer", value: ms(tracker.visionMs))
            row(label: "comp", value: ms(tracker.compositeMs))
            row(label: "out", value: ms(tracker.copyOutMs))
            row(label: "total", value: ms(tracker.transformMs))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.55))
        .cornerRadius(8)
    }

    private func ms(_ value: Double) -> String {
        value > 0 ? String(format: "%.1fms", value) : "—"
    }

    private func row(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .foregroundStyle(.white)
        }
        .font(.system(.caption2, design: .monospaced))
    }
}

#if DEBUG
    #Preview("Performance HUD — idle") {
        PerformanceHUDView()
            .padding()
            .background(Color.gray)
    }
#endif
