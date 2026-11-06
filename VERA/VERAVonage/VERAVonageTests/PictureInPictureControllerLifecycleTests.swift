import Foundation
import Testing

@testable import VERAVonage

@MainActor
@Suite("Picture-in-picture callback lifetimes")
struct PictureInPictureControllerLifecycleTests {
    private struct StubError: Error {}

    @Test("An unconfigured lifetime rejects every callback")
    func unconfiguredLifetimeRejectsCallbacks() {
        let lifecycle = PictureInPictureControllerLifecycle()
        let controller = NSObject()
        let id = ObjectIdentifier(controller)
        var events: [String] = []
        lifecycle.onStateDidStart = { events.append("start") }
        lifecycle.onDidStartRendering = { events.append("render") }
        lifecycle.onStateDidStop = { events.append("stop") }
        lifecycle.onPossibleDidChange = { events.append("possible") }
        lifecycle.onFailed = { _ in events.append("failed") }

        lifecycle.receive(.willStart, controllerID: id)
        lifecycle.receive(.didStart, controllerID: id)
        lifecycle.receive(.didStop, controllerID: id)
        lifecycle.receive(.possibleChanged, controllerID: id)
        lifecycle.receive(.failed(StubError()), controllerID: id)

        #expect(events.isEmpty)
        #expect(!lifecycle.isInPictureInPicture)
        withExtendedLifetime(controller) {}
    }

    @Test("Routed lifecycle events preserve state and callback order")
    func delegateCallbacks() {
        let lifecycle = PictureInPictureControllerLifecycle()
        let controller = NSObject()
        let id = ObjectIdentifier(controller)
        lifecycle.activate(controllerID: id)
        var events: [String] = []
        lifecycle.onStateDidStart = { events.append("start") }
        lifecycle.onDidStartRendering = { events.append("render") }
        lifecycle.onStateDidStop = { events.append("stop") }
        lifecycle.onPossibleDidChange = { events.append("possible") }
        lifecycle.onFailed = { _ in events.append("failed") }

        lifecycle.receive(.willStart, controllerID: id)
        #expect(lifecycle.isInPictureInPicture)
        lifecycle.receive(.didStart, controllerID: id)
        lifecycle.receive(.didStop, controllerID: id)
        #expect(!lifecycle.isInPictureInPicture)
        lifecycle.receive(.possibleChanged, controllerID: id)
        lifecycle.receive(.failed(StubError()), controllerID: id)
        #expect(!lifecycle.isInPictureInPicture)
        #expect(events == ["start", "render", "stop", "possible", "failed", "stop"])
        withExtendedLifetime(controller) {}
    }

    @Test("Callbacks from a replaced controller cannot mutate the current PiP lifetime")
    func replacedControllerCallbacksAreIgnored() {
        let lifecycle = PictureInPictureControllerLifecycle()
        let oldController = NSObject()
        let currentController = NSObject()
        let oldID = ObjectIdentifier(oldController)
        let currentID = ObjectIdentifier(currentController)
        lifecycle.activate(controllerID: oldID)
        lifecycle.activate(controllerID: currentID)
        var events: [String] = []
        lifecycle.onStateDidStart = { events.append("start") }
        lifecycle.onStateDidStop = { events.append("stop") }
        lifecycle.onPossibleDidChange = { events.append("possible") }
        lifecycle.onFailed = { _ in events.append("failed") }

        lifecycle.receive(.willStart, controllerID: oldID)
        lifecycle.receive(.didStop, controllerID: oldID)
        lifecycle.receive(.possibleChanged, controllerID: oldID)
        lifecycle.receive(.failed(StubError()), controllerID: oldID)
        #expect(events.isEmpty)
        #expect(!lifecycle.isInPictureInPicture)
        lifecycle.receive(.willStart, controllerID: currentID)
        #expect(lifecycle.isInPictureInPicture)
        lifecycle.receive(.didStop, controllerID: currentID)
        #expect(events == ["start", "stop"])
        #expect(!lifecycle.isInPictureInPicture)
        lifecycle.activate(controllerID: nil)
        lifecycle.receive(.willStart, controllerID: currentID)
        #expect(events == ["start", "stop"])
        #expect(!lifecycle.isInPictureInPicture)
        withExtendedLifetime((oldController, currentController)) {}
    }
    private struct Delivery: Sendable {
        let controllerID: ObjectIdentifier
        let event: PictureInPictureControllerEvent
    }

    @Test("Background events retain order while retired controller failures are ignored")
    func queuedEventsRejectRetiredControllers() async {
        let oldController = NSObject()
        let currentController = NSObject()
        let oldID = ObjectIdentifier(oldController)
        let currentID = ObjectIdentifier(currentController)
        let lifecycle = PictureInPictureControllerLifecycle()
        lifecycle.activate(controllerID: currentID)
        let queue = MainActorEventQueue<Delivery>()
        var events: [String] = []
        lifecycle.onStateDidStart = { events.append("start") }
        lifecycle.onStateDidStop = { events.append("stop") }
        lifecycle.onFailed = { _ in events.append("failed") }

        await withCheckedContinuation { continuation in
            lifecycle.onPossibleDidChange = { continuation.resume() }
            queue.activate { callback in
                lifecycle.receive(callback.event, controllerID: callback.controllerID)
            }
            Task.detached {
                queue.send(Delivery(controllerID: oldID, event: .willStart))
                queue.send(Delivery(controllerID: currentID, event: .willStart))
                queue.send(Delivery(controllerID: oldID, event: .failed(StubError())))
                queue.send(Delivery(controllerID: currentID, event: .didStop))
                queue.send(Delivery(controllerID: currentID, event: .possibleChanged))
            }
        }

        #expect(events == ["start", "stop"])
        #expect(!lifecycle.isInPictureInPicture)
        queue.invalidate()
        withExtendedLifetime((oldController, currentController)) {}
    }

    @Test("Failure-triggered replacement cannot receive the retired lifetime's stop callback")
    func replacementDuringFailureRetiresRemainingNotifications() {
        let controller = NSObject()
        let lifecycle = PictureInPictureControllerLifecycle()
        let id = ObjectIdentifier(controller)
        lifecycle.activate(controllerID: id)
        var stoppedNewLifetime = false
        lifecycle.onFailed = { _ in
            lifecycle.activate(controllerID: id)
            lifecycle.onStateDidStop = { stoppedNewLifetime = true }
        }

        lifecycle.receive(.failed(StubError()), controllerID: id)

        #expect(!stoppedNewLifetime)
        withExtendedLifetime(controller) {}
    }
}
