//
//  Created by Vonage on 20/02/2026.
//

import Combine
import Foundation
import Testing
import VERADomain

@testable import VERACaptions

@Suite("DefaultDisableCaptionsUseCase Tests")
struct DefaultDisableCaptionsUseCaseTests {

    @Test("Calling disable sets captions state to disabled")
    func disableSetsDisabledState() async throws {
        let statusDataSource = DefaultCaptionsStatusDataSource()
        statusDataSource.set(captionsState: .enabled("captions-123"))

        let sut = DefaultDisableCaptionsUseCase(captionsStatusDataSource: statusDataSource)

        sut()

        var state: CaptionsState = .enabled("should-change")
        let cancellable = statusDataSource.captionsState.sink { state = $0 }
        _ = cancellable

        #expect(state == .disabled)
    }

    @Test("Calling disable when already disabled remains disabled")
    func disableWhenAlreadyDisabled() async throws {
        let statusDataSource = DefaultCaptionsStatusDataSource()

        let sut = DefaultDisableCaptionsUseCase(captionsStatusDataSource: statusDataSource)

        sut()

        var state: CaptionsState = .enabled("should-not-be")
        let cancellable = statusDataSource.captionsState.sink { state = $0 }
        _ = cancellable

        #expect(state == .disabled)
    }
}
