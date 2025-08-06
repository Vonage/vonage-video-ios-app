//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

public class MeetingRoomFactory {
    private let currentCallParticipantsRepository: CurrentCallParticipantsRepository
    private let sessionRepository: SessionRepository
    private let publisherRepository: PublisherRepository
    private let roomCredentialsRepository: RoomCredentialsRepository

    public init(
        currentCallParticipantsRepository: CurrentCallParticipantsRepository,
        sessionRepository: SessionRepository,
        publisherRepository: PublisherRepository,
        roomCredentialsRepository: RoomCredentialsRepository
    ) {
        self.currentCallParticipantsRepository = currentCallParticipantsRepository
        self.sessionRepository = sessionRepository
        self.publisherRepository = publisherRepository
        self.roomCredentialsRepository = roomCredentialsRepository
    }

    public func make(
        roomName: RoomName,
        onBack: @escaping () -> Void
    ) -> some View {
        let viewModel = MeetingRoomViewModel(
            roomName: roomName,
            connectToRoomUseCase: .init(
                sessionRepository: sessionRepository,
                roomCredentialsRepository: roomCredentialsRepository),
            disconnectRoomUseCase: .init(
                sessionRepository: sessionRepository,
                publisherRepository: publisherRepository),
            currentCallParticipantsRepository: currentCallParticipantsRepository)
        viewModel.loadUI()
        return MeetingRoomScreen(
            viewModel: viewModel,
            onBack: onBack)
    }
}
