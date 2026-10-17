//
//  Created by Vonage on 17/10/26.
//

import SwiftUI
import VERAOnTheGo

@main
struct VERAOnTheGoDemoApp: App {
    var body: some Scene {
        WindowGroup {
            OnTheGoView(viewModel: Self.makeViewModel())
        }
    }

    @MainActor
    private static func makeViewModel() -> OnTheGoViewModel {
        let viewModel = OnTheGoViewModel(
            configuration: .init(),
            preferences: UserDefaultsOnTheGoPreferencesRepository(),
            motionProvider: nil,
            actions: OnTheGoCallActions(toggleMic: {}, toggleCamera: {}, endCall: {})
        )
        viewModel.update(
            snapshot: OnTheGoCallSnapshot(
                isConnected: true,
                isMicEnabled: true,
                isCameraEnabled: false,
                participantCount: 5,
                activeSpeakerName: "Alice",
                screenShareParticipant: nil
            )
        )
        return viewModel
    }
}
