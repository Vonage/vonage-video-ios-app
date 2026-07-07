//
//  Created by Vonage on 06/07/26.
//

#if canImport(UIKit)
    import Foundation
    import SwiftUI
    import VERACommonUI

    /// Creates VERAAudioDiagnostics views, view models, and buttons.
    ///
    /// This factory ensures consistent dependency injection across the audio diagnostics module,
    /// providing properly configured components for both waiting room and meeting room contexts.
    ///
    /// The factory holds a shared ``SpeakerTestService`` to ensure consistent audio testing
    /// across all instances.
    public final class AudioDiagnosticsFactory {

        /// Service used to play a test tone through the device's current audio output.
        private let speakerTestService: SpeakerTestService

        /// Creates a new audio diagnostics factory.
        ///
        /// - Parameter speakerTestService: Service that plays a test tone to verify audio output.
        public init(speakerTestService: SpeakerTestService) {
            self.speakerTestService = speakerTestService
        }

        // MARK: - View Model

        /// Creates a new ``AudioOutputControlViewModel``.
        ///
        /// - Returns: A configured view model for controlling audio output testing.
        @MainActor
        public func makeViewModel() -> AudioOutputControlViewModel {
            AudioOutputControlViewModel(speakerTestService: speakerTestService)
        }

        // MARK: - Dialog View

        /// Creates an ``AudioDiagnosticsDialog`` backed by a fresh view model.
        ///
        /// This dialog can be presented from any screen (Waiting Room, Meeting Room, Settings).
        ///
        /// - Returns: A configured audio diagnostics dialog.
        @MainActor
        public func makeDialog() -> AudioDiagnosticsDialog {
            let viewModel = makeViewModel()
            return AudioDiagnosticsDialog(viewModel: viewModel)
        }

        /// Creates an ``AudioDiagnosticsDialog`` with all presentation modifiers applied.
        ///
        /// This method ensures consistent presentation style across all usage contexts.
        /// The dialog is configured as a bottom sheet with:
        /// - Medium and large detent sizes
        /// - Hidden drag indicator (uses custom DragIndicatorView inside)
        /// - Opaque background with semantic color
        ///
        /// - Returns: A fully configured audio diagnostics dialog ready to be presented.
        @MainActor
        public func makeConfiguredDialog() -> AnyView {
            AnyView(
                makeDialog()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
                    .opaquePresentationBackground(VERACommonUIAsset.SemanticColors.background.swiftUIColor)
            )
        }

        // MARK: - Waiting Room Button

        /// Creates the circular speaker button for the waiting room.
        ///
        /// Provides a closure that creates an ``AudioDiagnosticsDialog`` when tapped.
        /// Falls back to a null service if the factory is deallocated.
        ///
        /// - Returns: A configured waiting room audio diagnostics button.
        @MainActor
        public func makeWaitingRoomButton() -> AudioDiagnosticsWaitingRoomButton {
            AudioDiagnosticsWaitingRoomButton(makeDialog: { [weak self] in
                guard let self else {
                    // Fallback to null service if factory is deallocated
                    let fallbackViewModel = AudioOutputControlViewModel(
                        speakerTestService: NullSpeakerTestService()
                    )
                    return AnyView(
                        AudioDiagnosticsDialog(viewModel: fallbackViewModel)
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.hidden)
                            .opaquePresentationBackground(VERACommonUIAsset.SemanticColors.background.swiftUIColor)
                    )
                }
                return self.makeConfiguredDialog()
            })
        }

        // MARK: - Meeting Room Button

        /// Creates the speaker button for the meeting room bottom bar or overflow menu.
        ///
        /// - Parameter onShowDialog: Closure fired when the button is tapped.
        ///   The caller is responsible for presenting the audio diagnostics dialog.
        /// - Returns: A configured meeting room audio diagnostics button.
        @MainActor
        public func makeMeetingRoomButton(
            onShowDialog: @escaping OnShowAudioDiagnostics
        ) -> AudioDiagnosticsMeetingRoomButton {
            AudioDiagnosticsMeetingRoomButton(onShowDialog: onShowDialog)
        }
    }

#endif
