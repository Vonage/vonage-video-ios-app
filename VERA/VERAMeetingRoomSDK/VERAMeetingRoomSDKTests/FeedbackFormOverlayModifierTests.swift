import SwiftUI
import Testing
import UIKit

@testable import VERAMeetingRoomSDK

@Suite("FeedbackFormOverlayModifier tests")
@MainActor
struct FeedbackFormOverlayModifierTests {

    @Test("Disabled modifier never presents sheet")
    func disabledDoesNotPresentSheet() async {
        let (root, window, box) = host(
            OverlayTestHost(isEnabled: false, initialShow: true)
        )

        // Give SwiftUI time to attempt presentation.
        try? await Task.sleep(for: .milliseconds(100))
        window.layoutIfNeeded()

        #expect(box.value == true)
        #expect(root.presentedViewController == nil)
    }

    @Test("Enabled modifier does not present when showFeedbackForm false")
    func enabledDoesNotPresentWhenFlagFalse() async {
        let (root, window, box) = host(
            OverlayTestHost(isEnabled: true, initialShow: false)
        )

        try? await Task.sleep(for: .milliseconds(100))
        window.layoutIfNeeded()

        #expect(box.value == false)
        #expect(root.presentedViewController == nil)
    }

    @Test("Enabled modifier presents sheet when showFeedbackForm true")
    func enabledPresentsWhenFlagTrue() async {
        let (root, window, box) = host(
            OverlayTestHost(isEnabled: true, initialShow: true)
        )

        // Presentation is asynchronous; give it a short runloop slice.
        try? await Task.sleep(for: .milliseconds(250))
        window.layoutIfNeeded()

        #expect(box.value == true)
        #expect(root.presentedViewController != nil)
    }
}

@MainActor
private func host<V: View>(_ view: V) -> (UIViewController, UIWindow, Box<Bool>) {
    let box = Box(false)
    let rootView = view.environment(\.overlayTestBox, box)

    let hosting = UIHostingController(rootView: rootView)
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
    window.rootViewController = hosting
    window.makeKeyAndVisible()
    hosting.view.setNeedsLayout()
    hosting.view.layoutIfNeeded()
    RunLoop.current.run(until: Date().addingTimeInterval(0.05))

    return (hosting, window, box)
}

@MainActor
private struct OverlayTestHost: View {
    let isEnabled: Bool
    @State var showFeedbackForm: Bool

    init(isEnabled: Bool, initialShow: Bool) {
        self.isEnabled = isEnabled
        self._showFeedbackForm = State(initialValue: initialShow)
    }

    @Environment(\.overlayTestBox) private var box

    var body: some View {
        Color.clear
            .modifier(
                FeedbackFormOverlayModifier(
                    isEnabled: isEnabled,
                    showFeedbackForm: $showFeedbackForm,
                    container: MeetingRoomSDKContainer(
                        baseURL: URL(string: "https://api.example.com")!,
                        enabledFeatures: [.screenShare, .feedback]
                    )
                )
            )
            .onAppear { box.value = showFeedbackForm }
    }
}

private final class Box<T> {
    var value: T
    init(_ value: T) { self.value = value }
}

private struct OverlayTestBoxKey: EnvironmentKey {
    static let defaultValue: Box<Bool> = Box(false)
}

extension EnvironmentValues {
    fileprivate var overlayTestBox: Box<Bool> {
        get { self[OverlayTestBoxKey.self] }
        set { self[OverlayTestBoxKey.self] = newValue }
    }
}
