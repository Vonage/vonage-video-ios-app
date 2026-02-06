//
//  Created by Vonage on 6/2/26.
//

import Foundation
import VERADomain

public struct DisableCaptionsRequest {
    public let roomName: String
    public let captionsID: CaptionsID

    public init(
        roomName: String,
        captionsID: CaptionsID
    ) {
        self.roomName = roomName
        self.captionsID = captionsID
    }
}

public protocol DisableCaptionsUseCase {
    func callAsFunction(_ request: DisableCaptionsRequest) async throws
}

public final class DefaultDisableCaptionsUseCase: DisableCaptionsUseCase {
    private let captionsDataSource: any CaptionsDataSource

    public init(captionsDataSource: any CaptionsDataSource) {
        self.captionsDataSource = captionsDataSource
    }

    public func callAsFunction(
        _ request: DisableCaptionsRequest
    ) async throws {
        let newRequest = DisableCaptionsDataSourceRequest(
            roomName: request.roomName,
            captionsID: request.captionsID
        )
        _ = try await captionsDataSource.disableCaptions(newRequest)
    }
}
