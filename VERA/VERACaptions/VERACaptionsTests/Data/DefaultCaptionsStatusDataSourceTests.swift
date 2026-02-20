//
//  Created by Vonage on 20/02/2026.
//

import Combine
import Foundation
import Testing
import VERADomain

@testable import VERACaptions

@Suite("DefaultCaptionsStatusDataSource Tests")
struct DefaultCaptionsStatusDataSourceTests {

    @Test("Initial state is disabled")
    func initialState() {
        let sut = DefaultCaptionsStatusDataSource()

        let state = currentState(of: sut)

        #expect(state == .disabled)
    }

    @Test("Setting state to enabled emits enabled")
    func setEnabled() {
        let sut = DefaultCaptionsStatusDataSource()

        sut.set(captionsState: .enabled("captions-123"))

        let state = currentState(of: sut)

        #expect(state == .enabled("captions-123"))
    }

    @Test("Setting state transitions correctly between enabled and disabled")
    func setTransitions() {
        let sut = DefaultCaptionsStatusDataSource()

        sut.set(captionsState: .enabled("id-1"))
        #expect(currentState(of: sut) == .enabled("id-1"))

        sut.set(captionsState: .disabled)
        #expect(currentState(of: sut) == .disabled)

        sut.set(captionsState: .enabled("id-2"))
        #expect(currentState(of: sut) == .enabled("id-2"))
    }

    @Test("Reset returns state to disabled regardless of current state")
    func resetToDisabled() {
        let sut = DefaultCaptionsStatusDataSource()

        sut.set(captionsState: .enabled("captions-456"))
        sut.reset()

        let state = currentState(of: sut)

        #expect(state == .disabled)
    }

    @Test("Reset when already disabled remains disabled")
    func resetWhenAlreadyDisabled() {
        let sut = DefaultCaptionsStatusDataSource()

        sut.reset()

        let state = currentState(of: sut)

        #expect(state == .disabled)
    }

    // MARK: - Helpers

    private func currentState(of dataSource: DefaultCaptionsStatusDataSource) -> CaptionsState {
        var state: CaptionsState = .disabled
        let cancellable = dataSource.captionsState.sink { state = $0 }
        _ = cancellable
        return state
    }
}
