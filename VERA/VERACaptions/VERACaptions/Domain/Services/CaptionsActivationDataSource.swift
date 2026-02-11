//
//  Created by Vonage on 6/2/26.
//

import Foundation

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

public struct DisableCaptionsDataSourceRequest {
    public let roomName: String
    public let captionsID: String

    public init(roomName: String, captionsID: String) {
        self.roomName = roomName
        self.captionsID = captionsID
    }
}

public typealias CaptionsID = String

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

    func disableCaptions(
        _ request: DisableCaptionsDataSourceRequest
    ) async throws
}
