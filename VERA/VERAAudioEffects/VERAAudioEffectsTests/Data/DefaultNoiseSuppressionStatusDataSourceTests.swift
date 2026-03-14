//
//  Created by Vonage on 13/3/26.
//

import Combine
import Testing
import VERAAudioEffects
import VERADomain

@Suite("DefaultNoiseSuppressionStatusDataSource tests")
struct DefaultNoiseSuppressionStatusDataSourceTests {

    @Test("Initial state is disabled")
    func initialStateIsDisabled() async throws {
        let sut = makeSUT()
        let recorder = StateRecorder()

        let cancellable = sut.noiseSuppressionState.sink { state in
            recorder.record(state)
        }

        #expect(recorder.states == [.disabled])
        cancellable.cancel()
    }

    @Test("Setting state to enabled updates publisher")
    func setStateToEnabled() async throws {
        let sut = makeSUT()
        let recorder = StateRecorder()

        let cancellable = sut.noiseSuppressionState.sink { state in
            recorder.record(state)
        }

        sut.set(state: .enabled)

        #expect(recorder.states == [.disabled, .enabled])
        cancellable.cancel()
    }

    @Test("Setting state to disabled updates publisher")
    func setStateToDisabled() async throws {
        let sut = makeSUT()
        let recorder = StateRecorder()

        let cancellable = sut.noiseSuppressionState.sink { state in
            recorder.record(state)
        }

        sut.set(state: .enabled)
        sut.set(state: .disabled)

        #expect(recorder.states == [.disabled, .enabled, .disabled])
        cancellable.cancel()
    }

    @Test("Multiple state changes are all emitted")
    func multipleStateChanges() async throws {
        let sut = makeSUT()
        let recorder = StateRecorder()

        let cancellable = sut.noiseSuppressionState.sink { state in
            recorder.record(state)
        }

        sut.set(state: .enabled)
        sut.set(state: .disabled)
        sut.set(state: .enabled)
        sut.set(state: .disabled)

        #expect(recorder.states == [.disabled, .enabled, .disabled, .enabled, .disabled])
        cancellable.cancel()
    }

    @Test("Setting same state multiple times emits each time")
    func settingSameStateMultipleTimes() async throws {
        let sut = makeSUT()
        let recorder = StateRecorder()

        let cancellable = sut.noiseSuppressionState.sink { state in
            recorder.record(state)
        }

        sut.set(state: .enabled)
        sut.set(state: .enabled)

        #expect(recorder.states == [.disabled, .enabled, .enabled])
        cancellable.cancel()
    }

    @Test("Publisher emits current value to new subscribers")
    func publisherEmitsCurrentValueToNewSubscribers() async throws {
        let sut = makeSUT()

        sut.set(state: .enabled)

        let recorder = StateRecorder()
        let cancellable = sut.noiseSuppressionState.sink { state in
            recorder.record(state)
        }

        #expect(recorder.states == [.enabled])
        cancellable.cancel()
    }

    @Test("Multiple subscribers receive same values")
    func multipleSubscribers() async throws {
        let sut = makeSUT()
        let recorder1 = StateRecorder()
        let recorder2 = StateRecorder()

        let cancellable1 = sut.noiseSuppressionState.sink { state in
            recorder1.record(state)
        }

        let cancellable2 = sut.noiseSuppressionState.sink { state in
            recorder2.record(state)
        }

        sut.set(state: .enabled)

        #expect(recorder1.states == [.disabled, .enabled])
        #expect(recorder2.states == [.disabled, .enabled])

        cancellable1.cancel()
        cancellable2.cancel()
    }

    // MARK: - Test Helpers

    private func makeSUT() -> DefaultNoiseSuppressionStatusDataSource {
        DefaultNoiseSuppressionStatusDataSource()
    }
}

// MARK: - Test Doubles

final class StateRecorder {
    private(set) var states: [NoiseSuppressionState] = []

    func record(_ state: NoiseSuppressionState) {
        states.append(state)
    }
}
