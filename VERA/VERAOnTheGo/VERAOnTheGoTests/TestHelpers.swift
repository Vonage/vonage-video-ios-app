//
//  Created by Vonage on 17/10/26.
//

import Combine
import Foundation

@testable import VERAOnTheGo

// MARK: - FakeMotionActivityProvider

@MainActor
final class FakeMotionActivityProvider: MotionActivityProviding {
    var isAvailable = true
    var authorizationStatus: MotionAuthorizationStatus = .authorized

    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var isRunning = false

    private var handler: (@MainActor (MotionSample) -> Void)?

    func start(_ handler: @escaping @MainActor (MotionSample) -> Void) {
        startCount += 1
        isRunning = true
        self.handler = handler
    }

    func stop() {
        stopCount += 1
        isRunning = false
        handler = nil
    }

    /// Feeds a sample as if it came from the device. Tests run on the main
    /// actor, matching the real contract.
    func emit(_ sample: MotionSample) {
        handler?(sample)
    }
}

// MARK: - InMemoryOnTheGoPreferencesRepository

@MainActor
final class InMemoryOnTheGoPreferencesRepository: OnTheGoPreferencesRepository {
    private let subject: CurrentValueSubject<Bool, Never>

    init(suggestWhenMoving: Bool = true) {
        subject = CurrentValueSubject(suggestWhenMoving)
    }

    var suggestWhenMoving: Bool {
        get { subject.value }
        set { subject.send(newValue) }
    }

    var suggestWhenMovingPublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }
}

// MARK: - SpyCallActions

/// Records every call the view model makes through ``OnTheGoCallActions``.
@MainActor
final class SpyCallActions {
    private(set) var toggleMicCount = 0
    private(set) var toggleCameraCount = 0
    private(set) var endCallCount = 0

    var actions: OnTheGoCallActions {
        OnTheGoCallActions(
            toggleMic: { [self] in toggleMicCount += 1 },
            toggleCamera: { [self] in toggleCameraCount += 1 },
            endCall: { [self] in endCallCount += 1 }
        )
    }
}

// MARK: - ManualTimeoutScheduler

/// Captures the scheduled timeout closure so tests can fire it deterministically.
@MainActor
final class ManualTimeoutScheduler {
    private(set) var scheduledWork: (@MainActor () -> Void)?
    private(set) var scheduledInterval: TimeInterval?
    private(set) var cancelled = false

    var schedule: @MainActor (TimeInterval, @escaping @MainActor () -> Void) -> AnyCancellable {
        { interval, work in
            self.scheduledInterval = interval
            self.scheduledWork = work
            return AnyCancellable { [weak self] in
                self?.cancelled = true
                self?.scheduledWork = nil
            }
        }
    }

    /// Fires the stored timeout closure.
    func fire() {
        let work = scheduledWork
        scheduledWork = nil
        work?()
    }
}

// MARK: - Factories

extension MotionSample {
    static func make(
        kind: Kind = .walking,
        confidence: Confidence = .medium,
        at seconds: TimeInterval
    ) -> MotionSample {
        MotionSample(
            kind: kind,
            confidence: confidence,
            timestamp: Date(timeIntervalSince1970: seconds)
        )
    }
}

extension OnTheGoCallSnapshot {
    static func connected(
        isMicEnabled: Bool = true,
        isCameraEnabled: Bool = true,
        participantCount: Int = 3,
        activeSpeakerName: String? = "Alice",
        screenShareParticipant: Participant? = nil
    ) -> OnTheGoCallSnapshot {
        OnTheGoCallSnapshot(
            isConnected: true,
            isMicEnabled: isMicEnabled,
            isCameraEnabled: isCameraEnabled,
            participantCount: participantCount,
            activeSpeakerName: activeSpeakerName,
            screenShareParticipant: screenShareParticipant
        )
    }
}
