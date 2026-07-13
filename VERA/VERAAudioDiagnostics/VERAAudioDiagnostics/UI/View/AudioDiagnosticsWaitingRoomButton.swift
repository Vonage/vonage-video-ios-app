//
//  Created by Vonage on 08/07/26.
//

#if canImport(UIKit)
    import SwiftUI
    import VERACommonUI

    public typealias OnLaunchAudioDiagnostics = () -> AnyView

    /// Selector-styled button shown next to the Camera selector in the waiting room.
    ///
    /// Unlike ``AudioDiagnosticsWaitingRoomButton`` (a circular icon button), this button
    /// matches the text + icon `Label` style used by the Camera selector, with no dropdown
    /// menu. Tapping opens the ``AudioDiagnosticsView`` directly in a sheet.
    ///
    /// The button creates the view lazily via the `makeView` closure,
    /// ensuring resources are allocated only when needed.
    public struct AudioDiagnosticsWaitingRoomButton: View {

        /// Closure for creating the audio diagnostics view when the button is tapped.
        /// If `nil`, the button will show the sheet but with no content.
        private let makeView: OnLaunchAudioDiagnostics?

        /// Controls the presentation state of the view sheet.
        @State private var showView = false

        /// Creates a new waiting room audio diagnostics button.
        ///
        /// - Parameter makeView: Optional closure that creates the view.
        ///                       Typically provided by ``AudioDiagnosticsFactory``.
        public init(makeView: OnLaunchAudioDiagnostics? = nil) {
            self.makeView = makeView
        }

        public var body: some View {
            Button(action: { showView = true }) {
                Label {
                    Text("Audio", bundle: .module)
                        .adaptiveFont(.bodyBase)
                } icon: {
                    VERACommonUIAsset.Images.audioMidLine.swiftUIImage
                }
            }
            .accessibilityIdentifier(AudioDiagnosticsAccessibilityID.waitingRoomButton)
            .sheet(isPresented: $showView) {
                makeView?()
            }
        }
    }

    // MARK: - Previews

    #if DEBUG
        #Preview {
            AudioDiagnosticsWaitingRoomButton {
                AnyView(
                    AudioDiagnosticsView(
                        viewModel: AudioOutputControlViewModel(speakerTestService: NullSpeakerTestService())
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
                    .opaquePresentationBackground(VERACommonUIAsset.SemanticColors.background.swiftUIColor)
                )
            }
            .padding()
            .preferredColorScheme(.dark)
        }
    #endif

#endif
