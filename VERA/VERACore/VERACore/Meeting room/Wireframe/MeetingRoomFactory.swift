//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

public class MeetingRoomFactory {

    private let baseURL: URL
    private let httpClient: HTTPClient
    private let jsonDecoder: JSONDecoder
    private let currentCallParticipantsRepository: CurrentCallParticipantsRepository
    private let sessionRepository: SessionRepository

    public init(
        baseURL: URL,
        httpClient: HTTPClient,
        jsonDecoder: JSONDecoder,
        currentCallParticipantsRepository: CurrentCallParticipantsRepository,
        sessionRepository: SessionRepository
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.jsonDecoder = jsonDecoder
        self.currentCallParticipantsRepository = currentCallParticipantsRepository
        self.sessionRepository = sessionRepository
    }

    public func make(roomName: RoomName) -> some View {

        let viewModel = MeetingRoomViewModel(
            roomName: roomName,
            connectToRoomUseCase: .init(
                getRoomCredentialsUseCase: .init(baseURL: baseURL, httpClient: httpClient, jsonDecoder: jsonDecoder),
                sessionRepository: sessionRepository),
            currentCallParticipantsRepository: currentCallParticipantsRepository)
        return MeetingRoomScreen(viewModel: viewModel)
    }
}
