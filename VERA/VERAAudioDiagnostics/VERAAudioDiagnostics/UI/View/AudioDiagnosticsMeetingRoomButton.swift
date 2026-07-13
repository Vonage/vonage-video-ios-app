//
//  Created by Vonage on 06/07/26.
//

#if canImport(UIKit)
    import SwiftUI
    import VERACommonUI

    /// Closure invoked when the audio diagnostics button is tapped.
    ///
    /// Used by ``AudioDiagnosticsMeetingRoomButton`` to notify the parent that
    /// the user wants to open the audio diagnostics dialog.
    public typealias OnShowAudioDiagnostics = () -> Void

    /// Speaker button rendered in the meeting room bottom bar (inline or overflow menu).
    ///
    /// Uses ``OngoingActivityControlImageButton`` for consistent styling with other
    /// meeting-room controls. Tapping fires the `onShowDialog` closure; the
    /// sheet presentation is managed externally (in `VERAApp`) so it works both
    /// when the button is rendered directly and from the overflow `Menu`.
    ///
    /// Unlike ``AudioDiagnosticsWaitingRoomButton``, this button does not manage
    /// the sheet presentation itself. The caller is responsible for presenting
    /// the dialog when the closure is invoked.
    public struct AudioDiagnosticsMeetingRoomButton: View {

        /// Closure invoked when the speaker button is tapped.
        /// The caller should present the audio diagnostics dialog in response.
        private let onShowDialog: OnShowAudioDiagnostics?

        /// Creates a new meeting room audio diagnostics button.
        ///
        /// - Parameter onShowDialog: Optional closure called when the button is tapped.
        ///                           Typically provided by the parent view to handle sheet presentation.
        public init(onShowDialog: OnShowAudioDiagnostics? = nil) {
            self.onShowDialog = onShowDialog
        }

        public var body: some View {
            OngoingActivityControlImageButton(
                isActive: false,
                image: Image(systemName: "speaker.wave.2.fill"),
                action: {
                    onShowDialog?()
                }
            )
        }
    }

    // MARK: - Previews

    #if DEBUG
        #Preview {
            AudioDiagnosticsMeetingRoomButton {

            }
            .padding()
            .preferredColorScheme(.dark)
        }
    #endif

#endif
