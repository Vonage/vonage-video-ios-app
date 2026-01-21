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

    public init(
        roomName: RoomName,
        archivesRepository: ArchivesRepository,
        playRecordingUseCase: PlayRecordingUseCase,
    ) {
        self.roomName = roomName
        self.archivesRepository = archivesRepository
        self.playRecordingUseCase = playRecordingUseCase
    }

    @BackgroundActor
    public func loadData() async {
        await archivesRepository.getArchives(roomName: roomName)
            .receive(on: DispatchQueue.main)
            .map { [weak self] archives in
                guard let self else { return [] }
                return
                    archives
                    .reversed()
                    .enumerated()
                    .map { index, archive in
                        self.mapToUIArchive(archive, index: archives.count - index)
                    }
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

    public func mapToUIArchive(_ archive: Archive, index: Int) -> ArchiveUIData {
        var uiArchive = archive.toUIArchive(with: index)
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
    func toUIArchive(with index: Int) -> ArchiveUIData {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d h:mm a"
        let formattedDate = formatter.string(from: createdAt)

        let durationFormatted = formatDuration(duration)
        let sizeFormatted = formatSize(size)

        return .init(
            id: id,
            title: String(localized: "Recording \(index)", bundle: .veraArchiving),
            subtitle: String(
                localized: "\(durationFormatted) • \(sizeFormatted) • Created: \(formattedDate)",
                bundle: .veraArchiving
            ),
            isDownloadable: status == .available)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func formatSize(_ bytes: Int) -> String {
        let megabytes = Double(bytes) / 1_048_576.0  // 1024 * 1024

        if megabytes < 0.1 {
            let kilobytes = Double(bytes) / 1024.0
            return String(format: "%.1f KB", kilobytes)
        } else if megabytes < 10 {
            return String(format: "%.1f MB", megabytes)
        } else {
            return String(format: "%.0f MB", megabytes)
        }
    }
}
