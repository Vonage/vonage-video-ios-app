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
    private let captionsActivationDataSource: any CaptionsActivationDataSource
    private let captionsStatusDataSource: CaptionsStatusDataSource

    public init(
        captionsActivationDataSource: any CaptionsActivationDataSource,
        captionsStatusDataSource: CaptionsStatusDataSource
    ) {
        self.captionsActivationDataSource = captionsActivationDataSource
        self.captionsStatusDataSource = captionsStatusDataSource
    }

    public func callAsFunction(
        _ request: EnableCaptionsRequest
    ) async throws {
        let newRequest = EnableCaptionsDataSourceRequest(
            roomName: request.roomName
        )
        let response = try await captionsActivationDataSource.enableCaptions(newRequest)
        captionsStatusDataSource.set(captionsState: .enabled(response.captionsId))
    }
}
