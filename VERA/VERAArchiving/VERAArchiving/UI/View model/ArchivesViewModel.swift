//
//  Created by Vonage on 8/1/26.
//

import Combine
import Foundation
import Observation
import VERACommonUI
import VERADomain

@MainActor
@Observable
public final class ArchivesViewModel {
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored
    private let sessionKeyProvider: SessionKeyProvider
    @ObservationIgnored
    private let archivesRepository: ArchivesRepository
    @ObservationIgnored
    private let playRecordingUseCase: PlayRecordingUseCase
    @ObservationIgnored
    private let downloadTranscriptionUseCase: DownloadTranscriptionUseCase

    public var archives: [ArchiveUIData] = []
    public var error: AlertItem?
    /// A downloaded transcript waiting to be shared or saved by the user.
    public var sharedTranscript: ArchiveTranscript?
    /// Archives whose download is in progress.
    public private(set) var downloadingArchiveIDs: Set<UUID> = []

    public init(
        sessionKeyProvider: SessionKeyProvider,
        archivesRepository: ArchivesRepository,
        playRecordingUseCase: PlayRecordingUseCase,
        downloadTranscriptionUseCase: DownloadTranscriptionUseCase
    ) {
        self.sessionKeyProvider = sessionKeyProvider
        self.archivesRepository = archivesRepository
        self.playRecordingUseCase = playRecordingUseCase
        self.downloadTranscriptionUseCase = downloadTranscriptionUseCase
    }

    /// Starts loading the archives of the current session, replacing any earlier load.
    ///
    /// Clears the previous load's error so it is not shown again for a later meeting.
    public func loadData() async {
        cancellables.removeAll()
        error = nil

        await archivesRepository.getArchives(sessionKey: sessionKeyProvider.sessionKey)
            .sinkOnMainActor(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = AlertItem.goodbyeError(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] archives in
                    Task { @MainActor in
                        // Date and size formatting stays off the UI actor.
                        let rows = await Task { @BackgroundActor in
                            ArchivePresentation.rows(archives)
                        }.value
                        guard let self else { return }
                        self.archives = rows.map { self.attachingDownload($0.ui, for: $0.archive) }
                    }
                }
            )
            .store(in: &cancellables)
    }

    public func mapToUIArchives(_ archives: [Archive]) -> [ArchiveUIData] {
        ArchivePresentation.rows(archives).map { attachingDownload($0.ui, for: $0.archive) }
    }

    public func mapToUIArchive(_ archive: Archive, index: Int) -> ArchiveUIData {
        attachingDownload(archive.toUIArchive(with: index), for: archive)
    }

    private func attachingDownload(_ uiArchive: ArchiveUIData, for archive: Archive) -> ArchiveUIData {
        var uiArchive = uiArchive
        uiArchive.onDownload = { [weak self] in
            self?.downloadArchive(archive)
        }
        return uiArchive
    }

    /// Opens a recording, or downloads a transcript and offers it for sharing.
    ///
    /// Requests for an archive that is already downloading are ignored.
    public func downloadArchive(_ archive: Archive) {
        Task { @MainActor [weak self] in
            guard let self, downloadingArchiveIDs.insert(archive.id).inserted else { return }
            defer { downloadingArchiveIDs.remove(archive.id) }
            do {
                switch archive.kind {
                case .recording:
                    try await playRecordingUseCase(archive)
                case .transcription:
                    sharedTranscript = try await downloadTranscriptionUseCase(archive)
                }
            } catch {
                self.error = AlertItem.downloadError(error.localizedDescription)
            }
        }
    }
}

private struct PreparedArchive: Sendable {
    let archive: Archive
    let ui: ArchiveUIData
}

/// Newest-first archive rows. The formatting is not tied to the main actor.
private enum ArchivePresentation {
    static func rows(_ archives: [Archive]) -> [PreparedArchive] {
        let newestFirst = archives.sorted { $0.createdAt > $1.createdAt }
        var nextIndexByKind = Dictionary(grouping: newestFirst, by: \.kind).mapValues(\.count)
        return newestFirst.map { archive in
            let index = nextIndexByKind[archive.kind, default: 0]
            nextIndexByKind[archive.kind] = index - 1
            return PreparedArchive(archive: archive, ui: archive.toUIArchive(with: index))
        }
    }
}

extension Archive {

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d h:mm a"
        return formatter.string(from: createdAt)
    }

    var subtitle: String {
        let formattedDate = formattedDate
        let durationFormatted = formatDuration(duration)
        let sizeFormatted = formatSize(size)

        return String(
            localized: "\(durationFormatted) • \(sizeFormatted) • Created: \(formattedDate)",
            bundle: .veraArchiving
        )
    }

    func toUIArchive(with index: Int) -> ArchiveUIData {
        if isPending {
            return .init(
                id: id,
                kind: kind,
                title: kind.preparingTitle,
                subtitle: String(localized: "Please wait while we prepare your downloads", bundle: .veraArchiving),
                downloadState: .preparing)
        }
        return .init(
            id: id,
            kind: kind,
            title: kind.listTitle(index: index),
            subtitle: subtitle,
            downloadState: downloadURL == nil ? .unavailable : .ready)
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
