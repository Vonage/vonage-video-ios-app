//
//  Created by Vonage on 26/3/26.
//

import SwiftUI

/// Constants for AudioLevelIndicatorView layout and appearance
enum AudioLevelIndicatorConstants {
    /// Size of the circular indicator
    static let size: CGFloat = 32

    /// Width of each bar
    static let barWidth: CGFloat = 4

    /// Spacing between bars
    static let barSpacing: CGFloat = 4

    /// Corner radius of each bar
    static let barCornerRadius: CGFloat = 2

    /// Shadow radius for bars
    static let barShadowRadius: CGFloat = 1

    /// Multipliers for each bar height relative to audioLevel
    static let barMultipliers: [CGFloat] = [0.6, 0.85, 0.6]

    /// Minimum bar height ratio
    static let minBarRatio: CGFloat = 0.12

    /// Maximum bar height ratio
    static let maxBarRatio: CGFloat = 0.9

    /// Background opacity
    static let backgroundOpacity: Double = 0.6
}

/// A circular indicator with vertical bars that visually displays the current audio level.
///
/// The indicator shows 3 bars whose heights are proportional to the audio level,
/// providing a visual audio meter.
///
/// - Parameters:
///   - audioLevel: The current audio level (0.0 to 1.0).
///   - isMicEnabled: Whether the microphone is enabled.
///     The indicator is only visible when the mic is on.
public struct AudioLevelIndicatorView: View {

    private let audioLevel: Float
    private let isMicEnabled: Bool

    public init(audioLevel: Float, isMicEnabled: Bool) {
        self.audioLevel = audioLevel
        self.isMicEnabled = isMicEnabled
    }

    private var bars: [CGFloat] {
        AudioLevelIndicatorConstants.barMultipliers.map { CGFloat(audioLevel) * $0 }
    }

    public var body: some View {
        if isMicEnabled {
            HStack(spacing: AudioLevelIndicatorConstants.barSpacing) {
                ForEach(0..<bars.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: AudioLevelIndicatorConstants.barCornerRadius)
                        .fill(Color.white)
                        .frame(width: AudioLevelIndicatorConstants.barWidth)
                        .frame(
                            height: AudioLevelIndicatorConstants.size
                                * min(
                                    max(bars[index], AudioLevelIndicatorConstants.minBarRatio),
                                    AudioLevelIndicatorConstants.maxBarRatio))
                        .shadow(radius: AudioLevelIndicatorConstants.barShadowRadius)
                }
            }
            .frame(
                width: AudioLevelIndicatorConstants.size,
                height: AudioLevelIndicatorConstants.size)
            .background(Circle().fill(Color.black.opacity(AudioLevelIndicatorConstants.backgroundOpacity)))
            .animation(.easeInOut(duration: 0.15), value: audioLevel)
        }
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
