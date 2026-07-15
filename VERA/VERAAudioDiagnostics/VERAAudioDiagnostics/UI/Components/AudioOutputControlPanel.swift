//
//  Created by Vonage on 03/07/26.
//

#if canImport(UIKit)
    import AVFoundation
    import Combine
    import SwiftUI
    import UIKit
    import VERACommonUI
    import AVKit

    /// Unified audio output control panel.
    ///
    /// Layout:
    ///   Row 1 (top)    – AVRoutePickerView spanning full width, labelled "Audio Output"
    ///   Row 2 (bottom) – Play button on the left, horizontal audio level bar on the right
    ///
    /// This component is designed for use in VERAMeetingRoomSDK and can be used
    /// in Settings, Waiting Room, or any pre-call/in-call context.
    public struct AudioOutputControlPanel: View {

        @ObservedObject var viewModel: AudioOutputControlViewModel

        public init(viewModel: AudioOutputControlViewModel) {
            self.viewModel = viewModel
        }

        public var body: some View {
            VStack(spacing: 12) {
                // Row 1 – Audio Output route picker (full width)
                AudioRoutePickerRow()
                    .frame(height: 44)

                Divider()
                    .background(VERACommonUIAsset.SemanticColors.onBackground.swiftUIColor.opacity(0.2))

                // Row 2 – Play button + level bar
                HStack(spacing: 18) {
                    PlayStopButton(isPlaying: viewModel.isPlaying) {
                        viewModel.togglePlayback()
                    }
                    .accessibilityIdentifier(AudioDiagnosticsAccessibilityID.playButton)

                    AudioLevelBar(level: viewModel.currentAudioLevel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier(AudioDiagnosticsAccessibilityID.levelBar)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(VERACommonUIAsset.SemanticColors.background.swiftUIColor)
            )
        }
    }

    // MARK: - Audio Route Picker Row

    /// Full-width row that wraps the native iOS AVRoutePickerView.
    ///
    /// Uses the standard iOS audio route picker to select output devices.
    /// The native picker handles Speaker, Receiver, AirPlay, Bluetooth automatically.
    private struct AudioRoutePickerRow: UIViewRepresentable {

        /// Creates the UIView hierarchy for the audio route picker row.
        ///
        /// This method constructs a custom container view that overlays UI elements
        /// on top of an invisible `AVRoutePickerView` to create a cohesive design
        /// while maintaining native audio routing functionality.
        ///
        /// - Parameter context: The representable context (unused in this implementation)
        /// - Returns: A configured container view with:
        ///   - Speaker icon on the left
        ///   - "Audio Output" label in the center
        ///   - AirPlay icon on the right
        ///   - Invisible `AVRoutePickerView` covering the entire area for touch handling
        ///
        /// The `AVRoutePickerView` is made invisible by setting its tint colors to clear,
        /// but it still handles user interactions and presents the native audio routing sheet.
        func makeUIView(context: Context) -> UIView {
            let container = UIView()
            container.backgroundColor = .clear

            let iconView = UIImageView(
                image: VERACommonUIAsset.Images.audioMaxSolid.image
                    .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
            )
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.tintColor = VERACommonUIAsset.SemanticColors.onBackground.color
            iconView.isUserInteractionEnabled = false
            container.addSubview(iconView)

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = String(localized: "Audio Output", bundle: .module)
            label.textColor = VERACommonUIAsset.SemanticColors.onBackground.color
            label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            label.isUserInteractionEnabled = false
            container.addSubview(label)

            let rightIcon = UIImageView(
                image: UIImage(systemName: "airplayaudio")?
                    .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .medium))
            )
            rightIcon.translatesAutoresizingMaskIntoConstraints = false
            rightIcon.tintColor = VERACommonUIAsset.SemanticColors.primary.color
            rightIcon.isUserInteractionEnabled = false
            container.addSubview(rightIcon)

            let routePicker = AVRoutePickerView()
            routePicker.translatesAutoresizingMaskIntoConstraints = false
            routePicker.prioritizesVideoDevices = false
            routePicker.tintColor = .clear
            routePicker.activeTintColor = .clear
            routePicker.backgroundColor = .clear
            container.addSubview(routePicker)

            NSLayoutConstraint.activate([
                iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
                iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 22),
                iconView.heightAnchor.constraint(equalToConstant: 22),

                label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                label.trailingAnchor.constraint(lessThanOrEqualTo: rightIcon.leadingAnchor, constant: -8),

                rightIcon.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
                rightIcon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                rightIcon.widthAnchor.constraint(equalToConstant: 24),
                rightIcon.heightAnchor.constraint(equalToConstant: 24),

                routePicker.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                routePicker.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                routePicker.topAnchor.constraint(equalTo: container.topAnchor),
                routePicker.bottomAnchor.constraint(equalTo: container.bottomAnchor),

                container.heightAnchor.constraint(equalToConstant: 44),
            ])

            return container
        }

        /// Updates the UIView when SwiftUI state changes.
        ///
        /// This method is intentionally empty as the `AudioRoutePickerRow` is stateless
        /// and doesn't need to respond to external state changes. The `AVRoutePickerView`
        /// automatically updates its internal state when the system audio route changes.
        ///
        /// - Parameters:
        ///   - uiView: The container view created by `makeUIView(context:)`
        ///   - context: The representable context (unused in this implementation)
        func updateUIView(_ uiView: UIView, context: Context) {
            // Intentionally empty: AVRoutePickerView manages its own state internally
            // and requires no updates from SwiftUI after initial configuration.
        }
    }

    // MARK: - Play/Stop Button

    private struct PlayStopButton: View {
        let isPlaying: Bool
        let onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 6) {
                    icon
                        .font(.system(size: 18, weight: .medium))
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(VERACommonUIAsset.SemanticColors.onBackground.swiftUIColor)
                .frame(minWidth: 125)  // Min width to accommodate both "Play"/"Reproducir" and "Stop"/"Detener"
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(VERACommonUIAsset.SemanticColors.onBackground.swiftUIColor.opacity(0.15))
                )
            }
        }

        private var title: String {
            .init(localized: isPlaying ? "Stop" : "Play", bundle: .module)
        }

        private var icon: Image {
            .init(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
        }
    }

    // MARK: - Audio Level Bar

    private struct AudioLevelBar: View {
        let level: Float
        private let barCount = 10

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("OUT", bundle: .module)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(VERACommonUIAsset.SemanticColors.secondary.swiftUIColor.opacity(0.6))

                HStack(spacing: 3) {
                    ForEach(0..<barCount, id: \.self) { index in
                        let isActive = level > Float(index) / Float(barCount)
                        AudioLevelBarSegment(
                            isActive: isActive,
                            color: colorForBar(at: index)
                        )
                    }
                }
            }
            .animation(.linear(duration: 0.05), value: level)
        }

        private func colorForBar(at index: Int) -> Color {
            let percentage = Float(index) / Float(barCount)
            if percentage > 0.75 { return .red }
            if percentage > 0.5 { return .yellow }
            return .green
        }
    }

    private struct AudioLevelBarSegment: View {
        let isActive: Bool
        let color: Color

        var body: some View {
            Rectangle()
                .fill(isActive ? color : VERACommonUIAsset.SemanticColors.onBackground.swiftUIColor.opacity(0.2))
                .frame(width: 8, height: 16)
                .cornerRadius(2)
        }
    }

    // MARK: - Preview

    #if DEBUG
        struct AudioOutputControlPanel_Previews: PreviewProvider {
            static var previews: some View {
                ZStack {
                    Color.gray.ignoresSafeArea()
                    VStack(spacing: 32) {
                        AudioOutputControlPanel(
                            viewModel: AudioOutputControlViewModel(speakerTestService: NullSpeakerTestService())
                        )
                    }
                    .padding()
                }
                .preferredColorScheme(.dark)
            }
        }
    #endif

#endif
