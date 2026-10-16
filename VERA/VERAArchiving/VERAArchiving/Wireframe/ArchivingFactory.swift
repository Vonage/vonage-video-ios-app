//
//  Created by Vonage on 9/1/26.
//

import SwiftUI
import VERADomain

public final class ArchivingFactory {

    private let archivesRepository: ArchivesRepository
    private let archivingDataSource: ArchivingDataSource
    private let archivingStatusDataSource: ArchivingStatusDataSource
    private let transcriptionStatusDataSource: ArchivingStatusDataSource
    private let sessionKeyProvider: SessionKeyProvider

    /// - Parameters:
    ///   - archivingStatusDataSource: Status of the recording archive.
    ///   - transcriptionStatusDataSource: Status of the post-call transcription archive.
    public init(
        archivesRepository: ArchivesRepository,
        archivingDataSource: ArchivingDataSource,
        archivingStatusDataSource: ArchivingStatusDataSource,
        transcriptionStatusDataSource: ArchivingStatusDataSource = DefaultArchivingStatusDataSource(),
        sessionKeyProvider: SessionKeyProvider
    ) {
        self.archivesRepository = archivesRepository
        self.archivingDataSource = archivingDataSource
        self.archivingStatusDataSource = archivingStatusDataSource
        self.transcriptionStatusDataSource = transcriptionStatusDataSource
        self.sessionKeyProvider = sessionKeyProvider
    }

    /// Makes the start/stop control for the given archive kind.
    ///
    /// - Parameters:
    ///   - kind: Whether the control drives the recording or the post-call transcription.
    ///   - showAlert: Presents the start/stop confirmation dialogs.
    public func makeArchivingButton(
        kind: ArchiveKind = .recording,
        showAlert: @escaping (AlertItem) -> Void
    ) -> (view: some View, viewModel: ArchiveButtonViewModel) {
        let viewModel = ArchiveButtonViewModel(
            kind: kind,
            sessionKeyProvider: sessionKeyProvider,
            startArchivingUseCase: DefaultStartArchivingUseCase(
                archivingDataSource: archivingDataSource),
            stopArchivingUseCase: DefaultStopArchivingUseCase(
                archivingDataSource: archivingDataSource),
            archivingStatusDataSource: statusDataSource(for: kind),
            showAlert: showAlert)
        return (makeArchivingButton(viewModel: viewModel), viewModel)
    }

    public func makeArchivingButton(
        viewModel: ArchiveButtonViewModel
    ) -> some View {
        ArchiveScreenButton(viewModel: viewModel)
    }

    private func statusDataSource(for kind: ArchiveKind) -> ArchivingStatusDataSource {
        switch kind {
        case .recording: archivingStatusDataSource
        case .transcription: transcriptionStatusDataSource
        }
    }

    public func make(
        onPlay: @escaping (ArchiveRecording) -> Void
    ) -> (view: some View, viewModel: ArchivesViewModel) {
        let viewModel = ArchivesViewModel(
            sessionKeyProvider: sessionKeyProvider,
            archivesRepository: archivesRepository,
            playRecordingUseCase: DefaultPlayRecordingUseCase(
                onPlay: onPlay
            ))
        return (make(viewModel: viewModel), viewModel)
    }

    public func make(
        viewModel: ArchivesViewModel
    ) -> some View {
        ArchivesScreen(viewModel: viewModel)
    }
}
