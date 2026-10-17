//
//  Created by Vonage on 17/10/26.
//

#if DEBUG
    import Foundation

    /// Convenience constructor for previews and the demo app.
    extension OnTheGoViewModel {
        /// A view model connected to a fake call, with no motion provider.
        ///
        /// - Parameters:
        ///   - isMicEnabled: Mic state reported by the snapshot.
        ///   - withScreenShare: Whether a screen-share participant exists.
        @MainActor
        static func preview(
            isMicEnabled: Bool = true,
            withScreenShare: Bool = false
        ) -> OnTheGoViewModel {
            let viewModel = OnTheGoViewModel(
                configuration: .init(),
                preferences: UserDefaultsOnTheGoPreferencesRepository(
                    userDefaults: UserDefaults(suiteName: "VERAOnTheGoPreview") ?? .standard
                ),
                motionProvider: nil,
                actions: OnTheGoCallActions(toggleMic: {}, toggleCamera: {}, endCall: {})
            )
            viewModel.update(
                snapshot: OnTheGoCallSnapshot(
                    isConnected: true,
                    isMicEnabled: isMicEnabled,
                    isCameraEnabled: false,
                    participantCount: 5,
                    activeSpeakerName: "Alice",
                    screenShareParticipant: withScreenShare
                        ? .init(id: "share", name: "Screen share", isScreenshare: true)
                        : nil
                )
            )
            viewModel.enterManually()
            return viewModel
        }
    }
#endif
