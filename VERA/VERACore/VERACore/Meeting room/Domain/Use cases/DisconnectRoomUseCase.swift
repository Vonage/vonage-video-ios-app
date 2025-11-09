//
//  Created by Vonage on 28/7/25.
//

import Foundation

public final class DisconnectRoomUseCase {

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
