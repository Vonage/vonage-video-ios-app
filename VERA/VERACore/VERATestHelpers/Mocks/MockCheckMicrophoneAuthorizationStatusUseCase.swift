//
//  Created by Vonage on 1/12/25.
//

import Foundation
import VERACore

public func makeMockCheckMicrophoneAuthorizationStatusUseCase(
    isAuthorized: Bool = true,
    isDenied: Bool = false
) -> CheckMicrophoneAuthorizationStatusUseCase {
    MockCheckMicrophoneAuthorizationStatusUseCase(isAuthorized: isAuthorized,isDenied: isDenied)
}

public final class MockCheckMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase {
    public var isAuthorized: Bool = true
    public var isPermissionDenied: Bool = true

    public init(isAuthorized: Bool, isDenied:Bool) {
        self.isAuthorized = isAuthorized
        self.isPermissionDenied = isDenied
    }

    public func callAsFunction() -> Bool {
        isAuthorized
    }
    
    public func isDenied() -> Bool {
        isPermissionDenied
    }
}
