//
//  Created by Vonage on 06/07/26.
//

#if canImport(UIKit)
    import SwiftUI
    import VERACommonUI

    /// Closure that creates and returns a configured audio diagnostics view with presentation modifiers.
    ///
    /// Used by ``AudioDiagnosticsWaitingRoomButton`` to lazily instantiate the dialog
    /// when the user taps the button.
    public typealias OnLaunchAudioDiagnostics = () -> AnyView

    /// Circular speaker button shown in the waiting room's trailing button row.
    ///
    /// Tapping opens the ``AudioDiagnosticsDialog`` in a sheet modal presentation.
    /// Uses ``CircularControlImageButton`` from VERACommonUI for consistent styling.
    ///
    /// The button creates the dialog lazily via the `makeDialog` closure,
    /// ensuring resources are allocated only when needed.
    public struct AudioDiagnosticsWaitingRoomButton: View {

        /// Closure for creating the audio diagnostics dialog when the button is tapped.
        /// If `nil`, the button will show the sheet but with no content.
        private let makeDialog: OnLaunchAudioDiagnostics?

        /// Controls the presentation state of the dialog sheet.
        @State private var showDialog = false

        /// Creates a new waiting room audio diagnostics button.
        ///
        /// - Parameter makeDialog: Optional closure that creates the dialog view.
        ///                         Typically provided by ``AudioDiagnosticsFactory``.
        public init(makeDialog: OnLaunchAudioDiagnostics? = nil) {
            self.makeDialog = makeDialog
        }

        public var body: some View {
            CircularControlImageButton(
                isActive: true,
                image: Image(systemName: "speaker.wave.2.fill"),
                action: { showDialog = true }
            )
            .sheet(isPresented: $showDialog) {
                makeDialog?()
            }
        }
    }

    // MARK: - Previews

    #if DEBUG
        #Preview {
            AudioDiagnosticsWaitingRoomButton {
                AnyView(
                    AudioDiagnosticsDialog(
                        viewModel: AudioOutputControlViewModel(speakerTestService: NullSpeakerTestService())
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
                    .opaquePresentationBackground(VERACommonUIAsset.SemanticColors.background.swiftUIColor)
                )
            }
            .preferredColorScheme(.dark)
        }
    #endif

#endif
