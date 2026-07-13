//
//  Created by Vonage on 30/6/26.
//

import SwiftUI
import Testing
import VERAMeetingRoom

@testable import VERA

@MainActor
@Suite("Meeting room customization bottom bar tests")
struct MeetingRoomCustomizationBottomBarTests {

    @Test("Bottom bar builds with participants control")
    func bottomBarBuildsWithParticipantsControl() {
        let sut = MeetingRoomCustomizationBottomBar(
            context: makeBottomBarContext(participants: makeControl(id: "participants", image: "person.2"))
        )

        _ = sut.body
    }

    @Test("Bottom bar builds without participants control")
    func bottomBarBuildsWithoutParticipantsControl() {
        let sut = MeetingRoomCustomizationBottomBar(context: makeBottomBarContext(participants: nil))

        _ = sut.body
    }

    @Test("Bottom bar exposes required SDK controls")
    func bottomBarExposesRequiredSDKControls() {
        var selectedControlIds: [String] = []
        let context = makeBottomBarContext(
            participants: nil,
            microphone: makeControl(id: "microphone", image: "mic") {
                selectedControlIds.append("microphone")
            },
            camera: makeControl(id: "camera", image: "video") {
                selectedControlIds.append("camera")
            },
            endCall: makeControl(id: "end-call", image: "phone.down.fill") {
                selectedControlIds.append("end-call")
            }
        )
        let sut = MeetingRoomCustomizationBottomBar(context: context)

        sut.context.controls.microphone.action()
        sut.context.controls.camera.action()
        sut.context.controls.endCall.action()

        #expect(selectedControlIds == ["microphone", "camera", "end-call"])
    }

    @Test("Action button builds active, inactive, and destructive styles")
    func actionButtonBuildsStyles() {
        let sut = MeetingRoomCustomizationBottomBar(
            context: makeBottomBarContext(participants: makeControl(id: "participants", image: "person.2"))
        )

        _ = sut.actionButton(makeControl(id: "active", image: "mic", isActive: true))
        _ = sut.actionButton(makeControl(id: "inactive", image: "video", isActive: false))
        _ = sut.actionButton(makeControl(id: "end-call", image: "phone.down.fill"), role: .destructive)
        _ = sut.activeBackgroundColor(true)
        _ = sut.activeBackgroundColor(false)
    }

    @Test("Presentation button sends request through context handler")
    func presentationButtonSendsRequestThroughContextHandler() {
        var presentedRequest: MeetingRoomPresentationRequest?
        let sut = MeetingRoomCustomizationBottomBar(
            context: makeBottomBarContext(
                participants: nil,
                presentationHandler: MeetingRoomPresentationHandler(
                    present: { request in
                        presentedRequest = request
                    }
                )
            )
        )

        _ = sut.presentationButton(style: .overlay, image: Image(systemName: "rectangle.on.rectangle"))
        sut.context.presentationHandler.present(
            MeetingRoomPresentationRequest(
                id: "test-overlay",
                style: .overlay,
                title: "Overlay"
            )
        )

        #expect(presentedRequest?.style == .overlay)
    }

    @Test("Presentation buttons build all supported styles")
    func presentationButtonsBuildAllSupportedStyles() {
        let sut = MeetingRoomCustomizationBottomBar(context: makeBottomBarContext(participants: nil))

        _ = sut.presentationButton(style: .dialog, image: Image(systemName: "exclamationmark.bubble.fill"))
        _ = sut.presentationButton(style: .overlay, image: Image(systemName: "rectangle.on.rectangle"))
        _ = sut.presentationButton(style: .sheet, image: Image(systemName: "rectangle.bottomhalf.inset.filled"))
    }

    private func makeBottomBarContext(
        participants: MeetingRoomBottomBarControl?,
        presentationHandler: MeetingRoomPresentationHandler = .init(),
        microphone: MeetingRoomBottomBarControl? = nil,
        camera: MeetingRoomBottomBarControl? = nil,
        endCall: MeetingRoomBottomBarControl? = nil
    ) -> MeetingRoomBottomBarContext {
        MeetingRoomBottomBarContext(
            state: .initial,
            actions: .init(),
            buttons: [],
            controls: MeetingRoomBottomBarControls(
                microphone: microphone ?? makeControl(id: "microphone", image: "mic"),
                camera: camera ?? makeControl(id: "camera", image: "video"),
                participants: participants,
                layout: makeControl(id: "layout", image: "rectangle.grid.2x2"),
                endCall: endCall ?? makeControl(id: "end-call", image: "phone.down.fill")
            ),
            presentationHandler: presentationHandler
        )
    }

    private func makeControl(
        id: String,
        image: String,
        isActive: Bool = false,
        action: @escaping @MainActor () -> Void = {}
    ) -> MeetingRoomBottomBarControl {
        MeetingRoomBottomBarControl(
            id: id,
            label: id,
            image: Image(systemName: image),
            isActive: isActive
        ) {
            action()
        }
    }
}
