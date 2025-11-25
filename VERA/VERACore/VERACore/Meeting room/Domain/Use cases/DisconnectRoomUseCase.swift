//
//  Created by Vonage on 28/7/25.
//

import Foundation

public protocol DisconnectRoomUseCase {
    func callAsFunction() async throws
}

public final class DefaultDisconnectRoomUseCase: DisconnectRoomUseCase {

    private let sessionRepository: SessionRepository

    public init(
        sessionRepository: SessionRepository
    ) {
        self.sessionRepository = sessionRepository
    }

    public func callAsFunction() async throws {
        try await sessionRepository.currentCall?.disconnect()
    }
}
