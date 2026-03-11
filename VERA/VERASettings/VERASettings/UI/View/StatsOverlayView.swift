//
//  Created by Vonage on 21/02/26.
//

import SwiftUI
import VERACommonUI

/// Constants for StatsOverlayView layout and appearance.
///
/// Centralizes visual styling values for the stats overlay to ensure consistency.
public enum StatsOverlayUIConstants {
    /// Vertical spacing between "Live Stats" title and stats text.
    public static let spacing: CGFloat = 4

    /// Corner radius of the overlay background.
    public static let cornerRadius: CGFloat = 12

    /// Background opacity of the overlay (0.0 - 1.0).
    public static let backgroundOpacity: Double = 0.8

    /// Shadow opacity (0.0 - 1.0).
    public static let shadowOpacity: Double = 0.8

    /// Shadow blur radius in points.
    public static let shadowRadius: Double = 2

    /// Horizontal shadow offset in points.
    public static let shadowX: Double = 0

    /// Vertical shadow offset in points (positive = downward).
    public static let shadowY: Double = 2

}

/// A translucent overlay that displays publisher stats in the top-leading corner.
///
/// Shows real-time network statistics when the user enables "Sender Stats" in settings.
/// The overlay appears over the video UI, displaying formatted audio/video metrics
/// in a monospaced font for easy reading.
///
/// Visibility is controlled by ``StatsOverlayViewModel/isActive``.
/// Uses throttled updates (configured in ``StatsOverlayViewModel/statsUpdateInterval``)
/// to prevent text from changing too rapidly.
///
/// The overlay is non-interactive (``allowsHitTesting(false)``) so taps pass through to underlying UI.
public struct StatsOverlayView: View {

    /// View model driving the overlay's visibility and stats text.
    @ObservedObject var viewModel: StatsOverlayViewModel

    /// Creates a new stats overlay view.
    ///
    /// - Parameter viewModel: The view model providing stats data and visibility state.
    public init(viewModel: StatsOverlayViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            if viewModel.isActive {
                VStack(alignment: .leading, spacing: StatsOverlayUIConstants.spacing) {
                    Text("Live Stats".localized)
                        .font(.caption.monospaced().bold())
                        .foregroundStyle(.white)
                        .shadow(
                            color: .black.opacity(StatsOverlayUIConstants.shadowOpacity),
                            radius: StatsOverlayUIConstants.shadowRadius, x: StatsOverlayUIConstants.shadowX,
                            y: StatsOverlayUIConstants.shadowY)

                    Text(viewModel.statsText)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.white)
                        .shadow(
                            color: .black.opacity(StatsOverlayUIConstants.shadowOpacity),
                            radius: StatsOverlayUIConstants.shadowRadius, x: StatsOverlayUIConstants.shadowX,
                            y: StatsOverlayUIConstants.shadowY)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: StatsOverlayUIConstants.cornerRadius)
                        .fill(
                            VERACommonUIAsset.Colors.vGray4.swiftUIColor.opacity(
                                StatsOverlayUIConstants.backgroundOpacity))
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
                .allowsHitTesting(false)
            } else {
                EmptyView()
            }
        }.onAppear {
            viewModel.setup()
        }
        .onDisappear {
            viewModel.removeObservers()
        }
    }
}

// MARK: - Previews

#if DEBUG
    #Preview("Stats Active") {
        StatsOverlayView(viewModel: .previewActive)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    #Preview("Stats Inactive") {
        StatsOverlayView(viewModel: .previewInactive)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
#endif
