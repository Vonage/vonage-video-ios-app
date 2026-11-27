import Combine
import Testing
import UIKit
import VERADomain

@testable import VERAVonage

@Suite("Picture in Picture recording status")
@MainActor
struct PictureInPictureRecordingTests {
    @Test("The content surface shows recording status and hides it when recording stops")
    func contentSurface() throws {
        let view = PictureInPictureSampleBufferView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
        let indicator = try #require(
            view.subviews.first {
                $0.accessibilityIdentifier == "archiving-recording-indicator"
            })
        #expect(indicator.isHidden)
        view.isRecording = true
        view.layoutIfNeeded()
        #expect(!indicator.isHidden)
        #expect(view.bounds.contains(indicator.frame))
        view.isRecording = false
        #expect(indicator.isHidden)
    }

    @Test("Reconfiguring an anchor preserves recording, while teardown clears it")
    func controllerLifecycle() {
        let controller = PictureInPictureController()
        controller.isRecording = true
        controller.configure(with: UIView())
        #expect(controller.isRecording)
        controller.configure(with: UIView())
        #expect(controller.isRecording)
        controller.tearDown()
        #expect(!controller.isRecording)
    }

    @Test("An already recording call and subsequent stop/start events update PiP")
    func observesRecording() async {
        let states = CurrentValueSubject<ArchivingState, Never>(.archiving("existing"))
        let orchestrator = PictureInPictureSessionOrchestrator()
        orchestrator.observeRecordingState(states.eraseToAnyPublisher())
        await drainMainQueue()
        #expect(orchestrator.isRecording)
        states.send(.idle)
        await drainMainQueue()
        #expect(!orchestrator.isRecording)
        states.send(.archiving("next"))
        await drainMainQueue()
        #expect(orchestrator.isRecording)
        orchestrator.tearDown()
    }

    @Test("Teardown discards queued and future recording updates from the old call")
    func teardownStopsObservation() async {
        let oldStates = CurrentValueSubject<ArchivingState, Never>(.idle)
        let orchestrator = PictureInPictureSessionOrchestrator()
        orchestrator.observeRecordingState(oldStates.eraseToAnyPublisher())
        oldStates.send(.archiving("old"))
        orchestrator.tearDown()
        await drainMainQueue()
        #expect(!orchestrator.isRecording)
        oldStates.send(.archiving("late"))
        let newStates = CurrentValueSubject<ArchivingState, Never>(.idle)
        orchestrator.observeRecordingState(newStates.eraseToAnyPublisher())
        await drainMainQueue()
        #expect(!orchestrator.isRecording)
        newStates.send(.archiving("new"))
        await drainMainQueue()
        #expect(orchestrator.isRecording)
        orchestrator.tearDown()
    }

    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
