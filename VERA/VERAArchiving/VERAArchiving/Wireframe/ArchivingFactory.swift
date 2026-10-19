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

    public init(
        archivesRepository: ArchivesRepository,
        archivingDataSource: ArchivingDataSource,
        archivingStatusDataSource: ArchivingStatusDataSource,
        sessionKeyProvider: SessionKeyProvider
    ) {
        self.archivesRepository = archivesRepository
        self.archivingDataSource = archivingDataSource
        self.archivingStatusDataSource = archivingStatusDataSource
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
            archivingStatusDataSource: archivingStatusDataSource,
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
            ))
        return (make(viewModel: viewModel), viewModel)
    }

    public func make(
        viewModel: ArchivesViewModel
    ) -> some View {
        ArchivesScreen(viewModel: viewModel)
    }
}
