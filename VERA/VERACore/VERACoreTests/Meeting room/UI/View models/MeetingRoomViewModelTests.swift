//
//  Created by Vonage on 29/7/25.
//

import Foundation
import VERACore
import Testing

@Suite("MeetingRoomViewModel tests")
struct MeetingRoomViewModelTests {
    
    @Test func zero() async throws {
        let sut = makeSUT()
        
        
    }
    
    // MARK: SUT
    
    func makeSUT(
        roomName: String = "a_room_name",
        connectToRoomUseCase: ConnectToRoomUseCase = .init(
            getRoomCredentialsUseCase: .init(baseURL: makeMockBaseURL(),
                                             httpClient: MockHTTPClient(),
                                             jsonDecoder: JSONDecoder()),
            sessionRepository: MockSessionRepository()),
        disconnectRoomUseCase: DisconnectRoomUseCase = .init(
            sessionRepository: MockSessionRepository(),
            publisherRepository: makeMockVERAPublisherRepository())
    ) -> MeetingRoomViewModel {
        return MeetingRoomViewModel(
            roomName: roomName,
            connectToRoomUseCase: connectToRoomUseCase,
            disconnectRoomUseCase: disconnectRoomUseCase,
            currentCallParticipantsRepository: MockCurrentCallParticipantsRepository())
    }
}
