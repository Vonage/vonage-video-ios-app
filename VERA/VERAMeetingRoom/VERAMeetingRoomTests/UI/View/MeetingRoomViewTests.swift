//
//  Created by Vonage on 30/6/26.
//

import SwiftUI
import Testing
import VERADomain

@testable import VERAMeetingRoom

@Suite("MeetingRoomView tests")
struct MeetingRoomViewTests {

    @Test("Bottom bar context includes available SDK controls")
    @MainActor
    func bottomBarContextIncludesAvailableSDKControls() throws {
        let controls = makeControls(
            state: makeState(
                allowMicrophoneControl: true,
                allowCameraControl: true,
                showParticipantList: true
            )
        )

        #expect(controls.microphone.id == "microphone")
        #expect(controls.camera.id == "camera")
        #expect(controls.participants?.id == "participants")
        #expect(controls.layout.id == "layout")
        #expect(controls.endCall.id == "end-call")
    }

    @Test("Bottom bar context keeps required controls and omits unavailable optional controls")
    @MainActor
    func bottomBarContextKeepsRequiredControlsAndOmitsUnavailableOptionalControls() throws {
        let controls = makeControls(
            state: makeState(
                allowMicrophoneControl: false,
                allowCameraControl: false,
                showParticipantList: false
            )
        )

        #expect(controls.microphone.id == "microphone")
        #expect(controls.camera.id == "camera")
        #expect(controls.participants == nil)
        #expect(controls.layout.id == "layout")
        #expect(controls.endCall.id == "end-call")
    }

    @Test("Bottom bar context controls reflect current state")
    @MainActor
    func bottomBarContextControlsReflectCurrentState() throws {
        let controls = makeControls(
            state: makeState(
                isMicEnabled: true,
                isCameraEnabled: true,
                layout: .grid
            )
        )

        #expect(controls.microphone.isActive == true)
        #expect(controls.camera.isActive == true)
        #expect(controls.layout.isActive == true)
        #expect(controls.participants?.isActive == false)
    }

    @Test("Bottom bar context exposes presentation handler")
    @MainActor
    func bottomBarContextExposesPresentationHandler() {
        var presentedRequest: MeetingRoomPresentationRequest?
        let context = MeetingRoomBottomBarContext(
            state: .initial,
            actions: .init(),
            buttons: [],
            controls: makeControls(state: makeState()),
            presentationHandler: MeetingRoomPresentationHandler(
                present: { request in
                    presentedRequest = request
                }
            )
        )

        context.presentationHandler.present(
            MeetingRoomPresentationRequest(
                id: "dialog-request",
                style: .dialog,
                title: "Dialog"
            )
        )

        #expect(presentedRequest?.id == "dialog-request")
        #expect(presentedRequest?.style == .dialog)
    }

    @MainActor
    private func makeControls(
        state: MeetingRoomState
    ) -> MeetingRoomBottomBarControls {
        MeetingRoomView(
            state: state,
            actions: .init()
        ).bottomBarControls
    }

    private func makeState(
        isMicEnabled: Bool = false,
        isCameraEnabled: Bool = false,
        layout: MeetingRoomLayout = .activeSpeaker,
        allowMicrophoneControl: Bool = true,
        allowCameraControl: Bool = true,
        showParticipantList: Bool = true
    ) -> MeetingRoomState {
        MeetingRoomState(
            roomName: "test-room",
            roomURL: nil,
            isMicEnabled: isMicEnabled,
            isCameraEnabled: isCameraEnabled,
            participants: [],
            layout: layout,
            activeSpeakerId: nil,
            allowMicrophoneControl: allowMicrophoneControl,
            allowCameraControl: allowCameraControl,
            showParticipantList: showParticipantList,
            callState: .connected,
            archivingState: .idle,
            noiseSuppressionState: .idle
        )
    }
}
