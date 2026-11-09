//
//  Created by Vonage on 9/1/26.
//

import SwiftUI
import VERADomain

public final class ArchivingFactory {

    private let archivesRepository: ArchivesRepository
    private let archivingDataSource: ArchivingDataSource
    private let archivingStatusDataSource: ArchivingStatusDataSource
    private let sessionKeyProvider: SessionKeyProvider
    private let archiveFileDownloader: ArchiveFileDownloader

    /// - Parameters:
    ///   - archiveFileDownloader: Downloads transcript zips on the goodbye page.
    public init(
        archivesRepository: ArchivesRepository,
        archivingDataSource: ArchivingDataSource,
        archivingStatusDataSource: ArchivingStatusDataSource,
        sessionKeyProvider: SessionKeyProvider,
        archiveFileDownloader: ArchiveFileDownloader = URLSessionArchiveFileDownloader()
    ) {
        self.archivesRepository = archivesRepository
        self.archivingDataSource = archivingDataSource
        self.archivingStatusDataSource = archivingStatusDataSource
        self.sessionKeyProvider = sessionKeyProvider
        self.archiveFileDownloader = archiveFileDownloader
    }

    /// Makes the start/stop control for the given archive kind.
    ///
    /// - Parameters:
    ///   - kind: Whether the control drives the recording or the post-call transcription.
    ///   - loadTranscriptionDefaults: Loads the options pre-selected when a transcription is started.
    ///   - showAlert: Presents the start/stop confirmation dialogs.
    public func makeArchivingButton(
        kind: ArchiveKind = .recording,
        loadTranscriptionDefaults: @escaping () async -> TranscriptionOptions = { .default },
        showAlert: @escaping (AlertItem) -> Void
    ) -> (view: some View, viewModel: ArchiveButtonViewModel) {
        let viewModel = ArchiveButtonViewModel(
            kind: kind,
            sessionKeyProvider: sessionKeyProvider,
            startArchivingUseCase: DefaultStartArchivingUseCase(
                archivingDataSource: archivingDataSource),
            stopArchivingUseCase: DefaultStopArchivingUseCase(
                archivingDataSource: archivingDataSource),
            archivingStatusDataSource: archivingStatusDataSource,
            loadTranscriptionDefaults: loadTranscriptionDefaults,
            showAlert: showAlert)
        return (makeArchivingButton(viewModel: viewModel), viewModel)
    }

    public func makeArchivingButton(
        viewModel: ArchiveButtonViewModel
    ) -> some View {
        ArchiveScreenButton(viewModel: viewModel)
    }

    public func make(
        onPlay: @escaping (ArchiveRecording) -> Void
    ) -> (view: some View, viewModel: ArchivesViewModel) {
        let viewModel = ArchivesViewModel(
            sessionKeyProvider: sessionKeyProvider,
            archivesRepository: archivesRepository,
            playRecordingUseCase: DefaultPlayRecordingUseCase(
                onPlay: onPlay
            ),
            downloadTranscriptionUseCase: DefaultDownloadTranscriptionUseCase(
                fileDownloader: archiveFileDownloader
            ))
        return (make(viewModel: viewModel), viewModel)
    }

    public func make(
        viewModel: ArchivesViewModel
    ) -> some View {
        ArchivesScreen(viewModel: viewModel)
    }
}
