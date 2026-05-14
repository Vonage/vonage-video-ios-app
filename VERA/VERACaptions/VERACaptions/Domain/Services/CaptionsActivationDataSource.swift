//
//  Created by Vonage on 6/2/26.
//

import Foundation
import VERADomain

public struct EnableCaptionsDataSourceRequest {
    public let sessionKey: String

    public init(sessionKey: String) {
        self.sessionKey = sessionKey
    }
}

public struct EnableCaptionsDataSourceResponse {
    public let captionsId: CaptionsID?

    public init(captionsId: CaptionsID?) {
        self.captionsId = captionsId
    }
}

public protocol CaptionsActivationDataSource {
    func enableCaptions(
        _ request: EnableCaptionsDataSourceRequest
    ) async throws -> EnableCaptionsDataSourceResponse
}
