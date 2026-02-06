//
//  Created by Vonage on 6/2/26.
//

import Foundation

public struct EnableCaptionsRequest {
    public let roomName: String

    public init(roomName: String) {
        self.roomName = roomName
    }
}

public protocol EnableCaptionsUseCase {
    func callAsFunction(_ request: EnableCaptionsRequest) async throws
}

public final class DefaultEnableCaptionsUseCase: EnableCaptionsUseCase {
    private let captionsDataSource: any CaptionsDataSource

    public init(captionsDataSource: any CaptionsDataSource) {
        self.captionsDataSource = captionsDataSource
    }

    public func callAsFunction(
        _ request: EnableCaptionsRequest
    ) async throws {
        let newRequest = EnableCaptionsDataSourceRequest(
            roomName: request.roomName
        )
        _ = try await captionsDataSource.enableCaptions(newRequest)
    }
}
