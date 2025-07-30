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
    private let publisherRepository: PublisherRepository

    public init(
        baseURL: URL,
        httpClient: HTTPClient,
        jsonDecoder: JSONDecoder,
        currentCallParticipantsRepository: CurrentCallParticipantsRepository,
        sessionRepository: SessionRepository,
        publisherRepository: PublisherRepository
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.jsonDecoder = jsonDecoder
        self.currentCallParticipantsRepository = currentCallParticipantsRepository
        self.sessionRepository = sessionRepository
        self.publisherRepository = publisherRepository
    }

    public func make(
        roomName: RoomName,
        onBack: @escaping () -> Void
    ) -> some View {
        let viewModel = MeetingRoomViewModel(
            roomName: roomName,
            connectToRoomUseCase: .init(
                getRoomCredentialsUseCase: .init(
                    baseURL: baseURL,
                    httpClient: httpClient,
                    jsonDecoder: jsonDecoder),
                sessionRepository: sessionRepository),
            disconnectRoomUseCase: .init(
                sessionRepository: sessionRepository,
                publisherRepository: publisherRepository),
            currentCallParticipantsRepository: currentCallParticipantsRepository)
        viewModel.loadUI()
        return MeetingRoomScreen(viewModel: viewModel, onBack: onBack)
    }
}
