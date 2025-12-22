//
//  Created by Vonage on 10/7/25.
//

import Combine
import Foundation
import Testing
import VERACore
import VERATestHelpers

@MainActor
@Suite("Landing page view model tests")
struct LandingPageViewModelTests {

    // MARK: - Initial State Tests

    @Test("Given initial state, when view model is created, then state should be content")
    func initialStateShouldBeContent() {
        let sut = makeSUT()

        #expect(sut.state == .content)
    }

    // MARK: - New Room Creation Tests

    @Test("Given initial state, when handle new room is selected then state changes to success with a non empty name")
    func whenHandleNewRoomIsSelectedThenStateChangesToSuccessWithANonEmptyName() {
        let sut = makeSUT()

        sut.onHandleNewRoom()

        switch sut.state {
        case .success(let roomName):
            #expect(!roomName.isEmpty)
        default:
            Issue.record("Expected success state with room name")
        }
    }

    @Test("Given content state, when handle new room is called, then state transitions to success")
    func whenHandleNewRoomIsCalledThenStateTransitionsToSuccess() {
        let sut = makeSUT()
        #expect(sut.state == .content)

        sut.onHandleNewRoom()

        switch sut.state {
        case .success:
            // Test passes
            break
        default:
            Issue.record("Expected state to transition to success")
        }
    }

    // MARK: - Join Room Tests

    @Test(
        """
        Given content state, when join room is called with valid name,
        then state transitions through loading to success
        """
    )
    func whenJoinRoomWithValidNameThenStateTransitionsToSuccess() async {
        let sut = makeSUT()
        let validRoomName = "validroom123"  // Use lowercase to match validation

        // Initial state should be content
        #expect(sut.state == .content)

        // Call join room
        sut.onJoinRoom(validRoomName)

        // Wait for async operation to complete with a reasonable timeout
        for _ in 0..<50 {  // Up to 0.5 seconds
            if case .success = sut.state {
                break
            }
            await delay()
        }

        // State should transition to success with the room name
        switch sut.state {
        case .success(let roomName):
            #expect(roomName == validRoomName)
        default:
            Issue.record("Expected success state with room name: \(validRoomName), got: \(sut.state)")
        }
    }

    // MARK: - Edge Cases

    @Test("Given content state, when join room is called with empty string, then state transitions to error")
    func whenJoinRoomIsCalledWithEmptyStringThenStateTransitionsToError() async {
        let sut = makeSUT()

        sut.onJoinRoom("")

        let value = (await sut.$error.values.first { $0 != nil } as? AlertItem)!
        #expect(value.title == "Error")
    }

    // MARK: SUT

    func makeSUT(
        roomNameGenerator: RoomNameGenerator = makeBasicRoomNameGenerator(),
        tryJoinRoomUseCase: TryJoinRoomUseCase = DefaultTryJoinRoomUseCase()
    ) -> LandingPageViewModel {
        let tryCreatingANewRoomUseCase = DefaultTryCreatingANewRoomUseCase(roomNameGenerator: roomNameGenerator)
        return LandingPageViewModel(
            tryJoinRoomUseCase: tryJoinRoomUseCase,
            tryCreatingANewRoomUseCase: tryCreatingANewRoomUseCase
        )
    }
}
