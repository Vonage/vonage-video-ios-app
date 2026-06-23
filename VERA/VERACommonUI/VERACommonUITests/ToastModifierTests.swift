import SwiftUI
import Testing
import VERACommonUI
import VERADomain

#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

@MainActor
@Suite("Toast modifier tests")
struct ToastModifierTests {

    @Test("toast view extension builds ToastView")
    func toastItemViewBuilds() {
        let item = ToastItem(message: "Something failed", mode: .failure)
        _ = item.view.body
        #expect(item.view.item == item)
    }

    @Test("toast modifier hosts with top and bottom placement")
    func toastModifierHostsBothPlacements() {
        hostToast(holder: ToastHolder(), placement: .top)
        hostToast(holder: ToastHolder(), placement: .bottom)
    }

    @Test("toast modifier clears binding after reset delay")
    func toastModifierClearsBindingAfterResetDelay() async {
        let holder = ToastHolder()
        hostToast(holder: holder, visibleDuration: 0.05, resetDelay: 0.12, placement: .bottom)

        holder.toast = ToastItem(message: "Something failed", mode: .failure)
        settleRunLoop()

        try? await Task.sleep(for: .milliseconds(200))

        #expect(holder.toast == nil)
    }

    // MARK: - Helpers

    private func hostToast(
        holder: ToastHolder,
        visibleDuration: TimeInterval = 3,
        resetDelay: TimeInterval = 4.5,
        placement: Edge = .top
    ) {
        let view = ToastTestHost(
            holder: holder,
            visibleDuration: visibleDuration,
            resetDelay: resetDelay,
            placement: placement
        )

        #if canImport(AppKit)
            let hostingView = NSHostingView(rootView: view)
            hostingView.frame = CGRect(x: 0, y: 0, width: 320, height: 240)

            let window = NSWindow(
                contentRect: hostingView.frame,
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.contentView = hostingView
            window.makeKeyAndOrderFront(nil)
            window.layoutIfNeeded()
            hostingView.layoutSubtreeIfNeeded()
        #elseif canImport(UIKit)
            let hostingController = UIHostingController(rootView: view)
            hostingController.view.frame = CGRect(x: 0, y: 0, width: 320, height: 240)

            let window = UIWindow(frame: hostingController.view.frame)
            window.rootViewController = hostingController
            window.makeKeyAndVisible()
            hostingController.view.setNeedsLayout()
            hostingController.view.layoutIfNeeded()
        #endif

        settleRunLoop()
    }

    private func settleRunLoop() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }
}

@MainActor
private final class ToastHolder: ObservableObject {
    @Published var toast: ToastItem?
}

@MainActor
private struct ToastTestHost: View {
    @ObservedObject var holder: ToastHolder
    let visibleDuration: TimeInterval
    let resetDelay: TimeInterval
    let placement: Edge

    var body: some View {
        Color.clear
            .toast(
                toast: $holder.toast,
                visibleDuration: visibleDuration,
                resetDelay: resetDelay,
                placement: placement,
                verticalPadding: 12
            )
    }
}
