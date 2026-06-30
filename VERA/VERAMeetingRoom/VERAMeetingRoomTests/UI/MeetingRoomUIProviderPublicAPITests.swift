//
//  Created by Vonage on 30/6/26.
//

import Combine
import SwiftUI
import Testing

@testable import VERAMeetingRoom

@Suite("MeetingRoom UI provider public API tests")
struct MeetingRoomUIProviderPublicAPITests {

    @Test("Presentation request stores default content values")
    @MainActor
    func presentationRequestStoresDefaultContentValues() {
        var dismissed = false
        let request = MeetingRoomPresentationRequest(
            id: "dialog-request",
            style: .dialog,
            title: "Dialog",
            message: "Message",
            sourceButtonId: "source-button",
            onDismiss: {
                dismissed = true
            }
        )

        request.onDismiss?()

        #expect(request.id == "dialog-request")
        #expect(request.style == .dialog)
        #expect(request.title == "Dialog")
        #expect(request.message == "Message")
        #expect(request.content == nil)
        #expect(request.sourceButtonId == "source-button")
        #expect(dismissed)
    }

    @Test("Presentation request stores custom content")
    @MainActor
    func presentationRequestStoresCustomContent() {
        let request = MeetingRoomPresentationRequest(
            id: "sheet-request",
            style: .sheet,
            title: "Sheet"
        ) {
            Text("Custom")
        }

        #expect(request.id == "sheet-request")
        #expect(request.style == .sheet)
        #expect(request.title == "Sheet")
        #expect(request.content != nil)
    }

    @Test("Presentation handler invokes present and dismiss closures")
    @MainActor
    func presentationHandlerInvokesClosures() {
        var presentedRequest: MeetingRoomPresentationRequest?
        var dismissedId: String?
        let sut = MeetingRoomPresentationHandler(
            present: { request in
                presentedRequest = request
            },
            dismiss: { id in
                dismissedId = id
            }
        )

        sut.present(
            MeetingRoomPresentationRequest(
                id: "overlay-request",
                style: .overlay,
                title: "Overlay"
            )
        )
        sut.dismiss("overlay-request")

        #expect(presentedRequest?.id == "overlay-request")
        #expect(dismissedId == "overlay-request")
    }

    @Test("Bottom bar controls expose configured values and actions")
    @MainActor
    func bottomBarControlsExposeConfiguredValuesAndActions() {
        var microphoneActionCount = 0
        var cameraActionCount = 0
        var participantsActionCount = 0
        var layoutActionCount = 0
        var endCallActionCount = 0

        let controls = MeetingRoomBottomBarControls(
            microphone: makeControl(id: "microphone", isActive: true) {
                microphoneActionCount += 1
            },
            camera: makeControl(id: "camera") {
                cameraActionCount += 1
            },
            participants: makeControl(id: "participants") {
                participantsActionCount += 1
            },
            layout: makeControl(id: "layout") {
                layoutActionCount += 1
            },
            endCall: makeControl(id: "end-call") {
                endCallActionCount += 1
            }
        )

        controls.microphone.action()
        controls.camera.action()
        controls.participants?.action()
        controls.layout.action()
        controls.endCall.action()

        #expect(controls.microphone.id == "microphone")
        #expect(controls.microphone.isActive)
        #expect(controls.camera.id == "camera")
        #expect(controls.participants?.id == "participants")
        #expect(controls.layout.id == "layout")
        #expect(controls.endCall.id == "end-call")
        #expect(microphoneActionCount == 1)
        #expect(cameraActionCount == 1)
        #expect(participantsActionCount == 1)
        #expect(layoutActionCount == 1)
        #expect(endCallActionCount == 1)
    }

    @Test("Bottom bar context exposes state actions buttons controls and presenter")
    @MainActor
    func bottomBarContextExposesConfiguredValues() {
        let button = BottomBarButton(
            id: "custom-button",
            label: "Custom",
            image: Image(systemName: "star"),
            action: {}
        )
        let controls = MeetingRoomBottomBarControls(
            microphone: makeControl(id: "microphone"),
            camera: makeControl(id: "camera"),
            participants: nil,
            layout: makeControl(id: "layout"),
            endCall: makeControl(id: "end-call")
        )
        let context = MeetingRoomBottomBarContext(
            state: .initial,
            actions: .init(),
            buttons: [button],
            controls: controls,
            presentationHandler: .init()
        )

        #expect(context.state == .initial)
        #expect(context.buttons.map(\.id) == ["custom-button"])
        #expect(context.controls.participants == nil)
        #expect(context.controls.endCall.id == "end-call")
    }

    @Test("Default provider can be configured with buttons updates and custom content")
    @MainActor
    func defaultProviderCanBeConfigured() async {
        let updates = PassthroughSubject<Void, Never>()
        let sut = DefaultMeetingRoomUIProvider(
            bottomBarButtons: {
                [
                    BottomBarButton(
                        id: "custom-button",
                        label: "Custom",
                        image: Image(systemName: "star"),
                        action: {}
                    )
                ]
            },
            updates: updates.eraseToAnyPublisher(),
            bottomBarContent: { _ in AnyView(Text("Custom bar")) }
        )
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        updates.send()

        #expect(sut.bottomBarButtons().map(\.id) == ["custom-button"])
        #expect(sut.bottomBarContent(context: makeContext()) != nil)
        #expect(updateCount == 1)

        cancellable.cancel()
    }

    @MainActor
    private func makeControl(
        id: String,
        isActive: Bool = false,
        action: @escaping @MainActor () -> Void = {}
    ) -> MeetingRoomBottomBarControl {
        MeetingRoomBottomBarControl(
            id: id,
            label: id,
            image: Image(systemName: "circle"),
            isActive: isActive,
            accessibilityIdentifier: "\(id)-identifier",
            action: action
        )
    }

    @MainActor
    private func makeContext() -> MeetingRoomBottomBarContext {
        MeetingRoomBottomBarContext(
            state: .initial,
            actions: .init(),
            buttons: [],
            controls: MeetingRoomBottomBarControls(
                microphone: makeControl(id: "microphone"),
                camera: makeControl(id: "camera"),
                participants: nil,
                layout: makeControl(id: "layout"),
                endCall: makeControl(id: "end-call")
            )
        )
    }
}
