//
//  Created by Vonage on 6/2/26.
//

import Foundation
import VERADomain

public enum CaptionsDataSourceError: Swift.Error {
    case networkError
    case invalidData
}

public struct EnableCaptionsDataSourceRequest {
    public let roomName: String

    public init(roomName: String) {
        self.roomName = roomName
    }
}

public struct EnableCaptionsDataSourceResponse {
    public let captionsId: CaptionsID

    public init(captionsId: CaptionsID) {
        self.captionsId = captionsId
    }
}

public protocol CaptionsActivationDataSource {
    func enableCaptions(
        _ request: EnableCaptionsDataSourceRequest
    ) async throws -> EnableCaptionsDataSourceResponse
}
