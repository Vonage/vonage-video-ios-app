//
//  Created by Vonage on 10/7/25.
//

import Foundation
import Testing
import VERACore

@Suite("Try creating a new room use case tests")
struct TryCreatingANewRoomUseCaseTests {

    @Test
    func createsANewRoom() {
        let sut = makeSUT()

        let roomName = sut.invoke()

        #expect(!roomName.isEmpty)
    }

    // MARK: - Helper

    private func makeSUT() -> TryCreatingANewRoomUseCase {
        let roomNameGenerator = makeBasicRoomNameGenerator()
        return TryCreatingANewRoomUseCase(roomNameGenerator: roomNameGenerator)
    }
}
