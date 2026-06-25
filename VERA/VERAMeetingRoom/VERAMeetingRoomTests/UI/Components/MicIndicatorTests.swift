import SwiftUI
import Testing

@testable import VERAMeetingRoom

#if os(macOS)
    import AppKit
    private typealias HostingController<Content: View> = NSHostingController<Content>
#else
    import UIKit
    private typealias HostingController<Content: View> = UIHostingController<Content>
#endif

@Suite("Mic indicator tests")
@MainActor
struct MicIndicatorTests {
    @Test
    func enabledMicrophoneWithActionIsInteractive() {
        var actionCount = 0
        let sut = MicIndicator(
            isMicEnabled: true,
            participantName: "Arthur",
            onForceMute: { actionCount += 1 }
        )

        #expect(sut.isForceMuteEnabled)
        #expect(sut.forceMuteAccessibilityLabel == "Mute Arthur")
        _ = host(sut)
        sut.onForceMute?()
        #expect(actionCount == 1)
    }

    @Test
    func enabledMicrophoneWithoutActionIsOnlyAnIndicator() {
        let sut = MicIndicator(
            isMicEnabled: true,
            participantName: "Ford",
            onForceMute: nil
        )

        #expect(!sut.isForceMuteEnabled)
        _ = host(sut)
    }

    @Test
    func mutedMicrophoneNeverExposesForceMuteAction() {
        let sut = MicIndicator(
            isMicEnabled: false,
            participantName: "Trillian",
            onForceMute: {}
        )

        #expect(!sut.isForceMuteEnabled)
        _ = host(sut)
    }

    @discardableResult
    private func host<V: View>(_ view: V) -> HostingController<V> {
        let controller = HostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        #if os(macOS)
            controller.view.layoutSubtreeIfNeeded()
        #else
            controller.view.layoutIfNeeded()
        #endif
        return controller
    }
}
