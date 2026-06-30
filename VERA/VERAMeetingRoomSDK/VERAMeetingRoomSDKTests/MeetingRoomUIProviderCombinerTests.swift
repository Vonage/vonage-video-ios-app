//
//  Created by Vonage on 30/6/26.
//

import Combine
import SwiftUI
import Testing
import VERAMeetingRoom

@testable import VERAMeetingRoomSDK

@MainActor
@Suite("MeetingRoomUIProviderCombiner tests")
struct MeetingRoomUIProviderCombinerTests {

    @Test("Returns SDK buttons when no custom provider is set")
    func returnsSDKButtonsWhenNoCustomProviderIsSet() {
        let sdkProvider = DefaultMeetingRoomUIProvider {
            [makeButton(id: "sdk")]
        }

        let provider = MeetingRoomUIProviderCombiner.combine(
            sdkProvider: sdkProvider,
            customProvider: nil
        )

        #expect(provider.bottomBarButtons().map(\.id) == ["sdk"])
    }

    @Test("Appends custom buttons after SDK buttons")
    func appendsCustomButtonsAfterSDKButtons() {
        let sdkProvider = DefaultMeetingRoomUIProvider {
            [makeButton(id: "sdk")]
        }
        let customProvider = DefaultMeetingRoomUIProvider {
            [makeButton(id: "custom")]
        }

        let provider = MeetingRoomUIProviderCombiner.combine(
            sdkProvider: sdkProvider,
            customProvider: customProvider
        )

        #expect(provider.bottomBarButtons().map(\.id) == ["sdk", "custom"])
    }

    @Test("Returns nil bottom bar content when no custom provider is set")
    func returnsNilBottomBarContentWhenNoCustomProviderIsSet() {
        let sdkProvider = DefaultMeetingRoomUIProvider {
            [makeButton(id: "sdk")]
        }

        let provider = MeetingRoomUIProviderCombiner.combine(
            sdkProvider: sdkProvider,
            customProvider: nil
        )

        #expect(provider.bottomBarContent(context: makeBottomBarContext()) == nil)
    }

    @Test("Exposes custom bottom bar content")
    func exposesCustomBottomBarContent() {
        let sdkProvider = DefaultMeetingRoomUIProvider {
            [makeButton(id: "sdk")]
        }
        let customProvider = DefaultMeetingRoomUIProvider(
            bottomBarButtons: { [makeButton(id: "custom")] },
            bottomBarContent: { context in
                AnyView(Text("Custom bottom bar with \(context.buttons.count) buttons"))
            }
        )

        let provider = MeetingRoomUIProviderCombiner.combine(
            sdkProvider: sdkProvider,
            customProvider: customProvider
        )

        #expect(provider.bottomBarContent(context: makeBottomBarContext()) != nil)
        #expect(provider.bottomBarButtons().map(\.id) == ["sdk", "custom"])
    }

    @Test("Emits SDK and custom updates")
    func emitsSDKAndCustomUpdates() {
        let sdkUpdates = PassthroughSubject<Void, Never>()
        let customUpdates = PassthroughSubject<Void, Never>()
        let sdkProvider = DefaultMeetingRoomUIProvider(
            bottomBarButtons: { [] },
            updates: sdkUpdates.eraseToAnyPublisher()
        )
        let customProvider = DefaultMeetingRoomUIProvider(
            bottomBarButtons: { [] },
            updates: customUpdates.eraseToAnyPublisher()
        )
        let provider = MeetingRoomUIProviderCombiner.combine(
            sdkProvider: sdkProvider,
            customProvider: customProvider
        )
        var updateCount = 0
        let cancellable = provider.updates.sink {
            updateCount += 1
        }

        sdkUpdates.send(())
        customUpdates.send(())

        #expect(updateCount == 2)
        cancellable.cancel()
    }

    private func makeButton(id: String) -> BottomBarButton {
        BottomBarButton(
            id: id,
            label: id,
            image: Image(systemName: "star")
        ) {}
    }

    private func makeBottomBarContext(
        buttons: [BottomBarButton] = []
    ) -> MeetingRoomBottomBarContext {
        MeetingRoomBottomBarContext(
            state: .initial,
            actions: .init(),
            buttons: buttons,
            controls: makeBottomBarControls()
        )
    }

    private func makeBottomBarControls() -> MeetingRoomBottomBarControls {
        MeetingRoomBottomBarControls(
            microphone: makeControl(id: "microphone", image: "mic"),
            camera: makeControl(id: "camera", image: "video"),
            participants: makeControl(id: "participants", image: "person.2"),
            layout: makeControl(id: "layout", image: "rectangle.grid.2x2"),
            endCall: makeControl(id: "end-call", image: "phone.down.fill")
        )
    }

    private func makeControl(id: String, image: String) -> MeetingRoomBottomBarControl {
        MeetingRoomBottomBarControl(
            id: id,
            label: id,
            image: Image(systemName: image)
        ) {}
    }
}
