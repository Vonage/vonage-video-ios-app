//
//  Created by Vonage on 30/7/25.
//

import Combine
import Foundation

public final class GoodByeViewModel: ObservableObject {
    private let roomName: RoomName
    private let joinRoomUseCase: JoinRoomUseCase
    private let userRepository: UserRepository
    private let archivesRepository: ArchivesRepository

    @Published public var archives: [ArchiveUIData] = []

    init(
        roomName: RoomName,
        joinRoomUseCase: JoinRoomUseCase,
        userRepository: UserRepository,
        archivesRepository: ArchivesRepository
    ) {
        self.roomName = roomName
        self.joinRoomUseCase = joinRoomUseCase
        self.userRepository = userRepository
        self.archivesRepository = archivesRepository
    }

    @BackgroundActor
    public func setupUI() {
        archivesRepository.getArchives(roomName: roomName)
            .map { archives in
                archives.map { $0.toUIArchive }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$archives)
    }

    @BackgroundActor
    public func joinRoom() async {
        do {
            let username = try await userRepository.get()?.name ?? ""
            let request = JoinRoomRequest(roomName: roomName, userName: username)
            try await joinRoomUseCase(request)
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension Archive {
    var toUIArchive: ArchiveUIData {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d h:mm a"
        let formattedDate = formatter.string(from: createdAt)

        return .init(
            id: id,
            title: name,
            subtitle: "Started at: \(formattedDate)",
            isDownloadable: status == .available)
    }
}
