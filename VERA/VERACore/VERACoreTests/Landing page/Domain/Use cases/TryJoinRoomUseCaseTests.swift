//
//  Created by Vonage on 9/7/25.
//

import Foundation
import Testing
import VERACore

@Suite("Try join room use case tests")
struct TryJoinRoomUseCaseTests {

    @Test
    func zero() async throws {
        let sut = makeSUT()

        try await sut.invoke("a room name")
    }

    // MARK: SUT

    func makeSUT() -> TryJoinRoomUseCase {
        return TryJoinRoomUseCase()
    }
}
