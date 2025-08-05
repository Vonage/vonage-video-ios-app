//
//  Created by Vonage on 30/7/25.
//

import Combine
import Foundation

public typealias GoodByeError = String

public final class GoodByeViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let roomName: RoomName
    private let joinRoomUseCase: JoinRoomUseCase
    private let userRepository: UserRepository
    private let archivesRepository: ArchivesRepository

    @Published public var archives: [ArchiveUIData] = []
    @Published public var error: AlertItem? = nil

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
    public func setupUI() async {
        await archivesRepository.getArchives(roomName: roomName)
            .map { archives in
                archives.map { $0.toUIArchive }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = AlertItem.goodbyeError(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] archives in
                    self?.archives = archives
                }
            )
            .store(in: &cancellables)
    }

    @BackgroundActor
    public func joinRoom() async {
        do {
            let username = try await userRepository.get()?.name ?? ""
            let request = JoinRoomRequest(roomName: roomName, userName: username)
            try await joinRoomUseCase(request)
        } catch {
            self.error = AlertItem.genericError(error.localizedDescription)
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
