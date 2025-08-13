//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

public class MeetingRoomFactory {
    private let baseURL: URL
    private let currentCallParticipantsRepository: CurrentCallParticipantsRepository
    private let sessionRepository: SessionRepository
    private let publisherRepository: PublisherRepository
    private let roomCredentialsRepository: RoomCredentialsRepository
    private let clipboard: Clipboard

    public init(
        baseURL: URL,
        currentCallParticipantsRepository: CurrentCallParticipantsRepository,
        sessionRepository: SessionRepository,
        publisherRepository: PublisherRepository,
        roomCredentialsRepository: RoomCredentialsRepository,
        clipboard: Clipboard
    ) {
        self.baseURL = baseURL
        self.currentCallParticipantsRepository = currentCallParticipantsRepository
        self.sessionRepository = sessionRepository
        self.publisherRepository = publisherRepository
        self.roomCredentialsRepository = roomCredentialsRepository
        self.clipboard = clipboard
    }

    public func make(
        roomName: RoomName,
        onBack: @escaping () -> Void
    ) -> some View {
        let viewModel = MeetingRoomViewModel(
            roomName: roomName,
            baseURL: baseURL,
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
            onCopyToClipboard: clipboard.copy,
            onBack: onBack)
    }
}
