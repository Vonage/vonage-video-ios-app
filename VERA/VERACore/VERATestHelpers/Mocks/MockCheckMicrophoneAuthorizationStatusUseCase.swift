//
//  Created by Vonage on 1/12/25.
//

import Foundation
import VERACore

public func makeMockCheckMicrophoneAuthorizationStatusUseCase(
    isAuthorized: Bool = true
) -> CheckMicrophoneAuthorizationStatusUseCase {
    MockCheckMicrophoneAuthorizationStatusUseCase(isAuthorized: isAuthorized)
}

public final class MockCheckMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase {
    public var isAuthorized: Bool = true

    public init(isAuthorized: Bool) {
        self.isAuthorized = isAuthorized
    }

    public func callAsFunction() -> Bool {
        isAuthorized
    }
}
