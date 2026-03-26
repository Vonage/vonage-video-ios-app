//
//  Created by Vonage on 26/3/26.
//

import SwiftUI

/// A circular indicator with vertical bars that visually displays the current audio level.
///
/// The indicator shows 4 bars of increasing height. Each bar lights up
/// when the audio level exceeds its threshold, providing a visual audio meter.
///
/// - Parameters:
///   - audioLevel: The current audio level (0.0 to 1.0).
///   - isMicEnabled: Whether the microphone is enabled.
///     The indicator is only visible when the mic is on.
public struct AudioLevelIndicatorView: View {

    private let audioLevel: Float
    private let isMicEnabled: Bool

    private let barCount = 4
    private let barWidth: CGFloat = 2.5
    private let barSpacing: CGFloat = 1.5
    private let barHeights: [CGFloat] = [0.3, 0.5, 0.7, 1.0]
    private let barThresholds: [Float] = [0.05, 0.25, 0.5, 0.75]

    public init(audioLevel: Float, isMicEnabled: Bool) {
        self.audioLevel = audioLevel
        self.isMicEnabled = isMicEnabled
    }

    public var body: some View {
        if isMicEnabled {
            HStack(alignment: .bottom, spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(barColor(for: index))
                        .frame(width: barWidth, height: barHeight(for: index))
                }
            }
            .frame(width: 28, height: 28)
            .background(Color.black.opacity(0.6))
            .clipShape(Circle())
            .animation(.easeInOut(duration: 0.15), value: audioLevel)
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let maxHeight: CGFloat = 14
        return maxHeight * barHeights[index]
    }

    private func barColor(for index: Int) -> Color {
        audioLevel >= barThresholds[index]
            ? VERACommonUIAsset.SemanticColors.success.swiftUIColor
            : Color.white.opacity(0.3)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            AudioLevelIndicatorView(audioLevel: 0.0, isMicEnabled: true)
            AudioLevelIndicatorView(audioLevel: 0.1, isMicEnabled: true)
            AudioLevelIndicatorView(audioLevel: 0.3, isMicEnabled: true)
            AudioLevelIndicatorView(audioLevel: 0.6, isMicEnabled: true)
            AudioLevelIndicatorView(audioLevel: 0.8, isMicEnabled: true)
            AudioLevelIndicatorView(audioLevel: 1.0, isMicEnabled: true)
        }

        HStack(spacing: 12) {
            AudioLevelIndicatorView(audioLevel: 0.5, isMicEnabled: false)
            Text("Hidden when mic off")
                .font(.caption)
        }
    }
    .padding()
    .background(VERACommonUIAsset.Colors.videoBackground.swiftUIColor)
}
