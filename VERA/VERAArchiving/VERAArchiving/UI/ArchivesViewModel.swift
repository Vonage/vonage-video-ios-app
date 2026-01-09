//
//  Created by Vonage on 8/1/26.
//

import Combine
import Foundation
import VERADomain

public final class ArchivesViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    public let roomName: RoomName
    private let archivesRepository: ArchivesRepository
    private let playRecordingUseCase: PlayRecordingUseCase

    @MainActor @Published public var archives: [ArchiveUIData] = []
    @MainActor @Published public var error: AlertItem?

    init(
        roomName: RoomName,
        archivesRepository: ArchivesRepository,
        playRecordingUseCase: PlayRecordingUseCase,
    ) {
        self.roomName = roomName
        self.archivesRepository = archivesRepository
        self.playRecordingUseCase = playRecordingUseCase
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
