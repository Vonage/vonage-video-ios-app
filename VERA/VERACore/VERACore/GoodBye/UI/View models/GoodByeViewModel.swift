//
//  Created by Vonage on 30/7/25.
//

import Combine
import Foundation
import VERADomain

public typealias GoodByeError = String

public struct GoodByeNavigation {
    public let onReenter: () -> Void
    public let onReturnToLanding: () -> Void

    public init(
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) {
        self.onReenter = onReenter
        self.onReturnToLanding = onReturnToLanding
    }
}

public final class GoodByeViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    public let roomName: RoomName
    private let joinRoomUseCase: JoinRoomUseCase
    private let userRepository: UserRepository
    private let archivesRepository: ArchivesRepository
    private let playRecordingUseCase: PlayRecordingUseCase
    private let goodByeNavigation: GoodByeNavigation

    @MainActor @Published public var archives: [ArchiveUIData] = []
    @MainActor @Published public var error: AlertItem?

    init(
        roomName: RoomName,
        joinRoomUseCase: JoinRoomUseCase,
        userRepository: UserRepository,
        archivesRepository: ArchivesRepository,
        playRecordingUseCase: PlayRecordingUseCase,
        goodByeNavigation: GoodByeNavigation
    ) {
        self.roomName = roomName
        self.joinRoomUseCase = joinRoomUseCase
        self.userRepository = userRepository
        self.archivesRepository = archivesRepository
        self.playRecordingUseCase = playRecordingUseCase
        self.goodByeNavigation = goodByeNavigation
    }

    @BackgroundActor
    public func setupUI() async {
        await archivesRepository.getArchives(roomName: roomName)
            .map { [weak self] archives in
                guard let self else { return [] }
                return archives.map { self.mapToUIArchive($0) }
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Task { @MainActor [weak self] in
                            self?.error = AlertItem.goodbyeError(error.localizedDescription)
                        }
                    }
                },
                receiveValue: { archives in
                    Task { @MainActor [weak self] in
                        self?.archives = archives
                    }
                }
            )
            .store(in: &cancellables)
    }

    public func mapToUIArchive(_ archive: Archive) -> ArchiveUIData {
        var uiArchive = archive.toUIArchive
        uiArchive.onDownload = { [weak self] in
            self?.downloadArchive(archive)
        }
        return uiArchive
    }

    public func downloadArchive(_ archive: Archive) {
        Task {
            do {
                try await playRecordingUseCase(archive)
            } catch {
                Task { @MainActor [weak self] in
                    self?.error = AlertItem.downloadError(error.localizedDescription)
                }
            }
        }
    }

    @BackgroundActor
    public func joinRoom() async {
        do {
            let username = try await userRepository.get()?.name ?? ""
            let request = JoinRoomRequest(roomName: roomName, userName: username)
            try await joinRoomUseCase(request)
        } catch {
            Task { @MainActor [weak self] in
                self?.error = AlertItem.genericError(error.localizedDescription)
            }
        }
    }

    public func onReenter() {
        Task { [weak self] in
            guard let self else { return }
            await joinRoom()
            await MainActor.run { [weak self] in
                self?.goodByeNavigation.onReenter()
            }
        }
    }

    public func onReturnToLanding() {
        goodByeNavigation.onReturnToLanding()
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
