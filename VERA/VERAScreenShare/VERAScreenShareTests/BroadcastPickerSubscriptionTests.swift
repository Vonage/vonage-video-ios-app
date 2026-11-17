#if os(iOS)
    import Combine
    import Testing
    import UIKit

    @testable import VERAScreenShare

    @MainActor
    @Suite("Broadcast picker subscription lifetime")
    struct BroadcastPickerSubscriptionTests {
        @Test("Repeated updates retain a single button action subscription")
        func repeatedBindingDoesNotDuplicateButtonActions() async {
            let coordinator = BroadcastPickerRepresentable.Coordinator()
            let button = UIButton(type: .custom)
            let target = ButtonTarget()
            button.addTarget(target, action: #selector(ButtonTarget.tapped), for: .touchUpInside)
            coordinator.broadcastButton = button
            let trigger = PassthroughSubject<Void, Never>()
            coordinator.observe(actionTrigger: trigger)
            coordinator.observe(actionTrigger: trigger)

            trigger.send()
            await drainMainQueue()

            #expect(target.tapCount == 1)
        }

        @Test("Replacing and stopping observation cancels previous triggers")
        func replacingAndStoppingObservationCancelsOldTriggers() async {
            let coordinator = BroadcastPickerRepresentable.Coordinator()
            let button = UIButton(type: .custom)
            let target = ButtonTarget()
            button.addTarget(target, action: #selector(ButtonTarget.tapped), for: .touchUpInside)
            coordinator.broadcastButton = button
            let old = PassthroughSubject<Void, Never>()
            let current = PassthroughSubject<Void, Never>()
            coordinator.observe(actionTrigger: old)
            coordinator.observe(actionTrigger: current)

            old.send()
            await drainMainQueue()
            #expect(target.tapCount == 0)
            current.send()
            await drainMainQueue()
            #expect(target.tapCount == 1)

            coordinator.stopObserving()
            current.send()
            await drainMainQueue()
            #expect(target.tapCount == 1)
            #expect(coordinator.broadcastButton == nil)
        }

        /// Receive-on delivery was queued before this barrier on the same serial main queue.
        private func drainMainQueue() async {
            await withCheckedContinuation { continuation in
                DispatchQueue.main.async { continuation.resume() }
            }
        }
    }

    @MainActor
    private final class ButtonTarget: NSObject {
        private(set) var tapCount = 0
        @objc func tapped() { tapCount += 1 }
    }
#endif
