//
//  Created by Vonage on 9/1/26.
//

import SwiftUI
import VERADomain

public final class ArchivingFactory {

    private let archivesRepository: ArchivesRepository
    private let archiveRecordingsRepository: ArchiveRecordingsRepository
    private let archivingDataSource: ArchivingDataSource
    private let archivingStatusDataSource: ArchivingStatusDataSource

    public init(
        archivesRepository: ArchivesRepository,
        archiveRecordingsRepository: ArchiveRecordingsRepository,
        archivingDataSource: ArchivingDataSource,
        archivingStatusDataSource: ArchivingStatusDataSource
    ) {
        self.archivesRepository = archivesRepository
        self.archiveRecordingsRepository = archiveRecordingsRepository
        self.archivingDataSource = archivingDataSource
        self.archivingStatusDataSource = archivingStatusDataSource
    }

    public func makeArchivingButton(
        roomName: RoomName
    ) -> (view: some View, viewModel: ArchiveButtonViewModel) {
        let viewModel = ArchiveButtonViewModel(
            roomName: roomName,
            startArchivingUseCase: DefaultStartArchivingUseCase(
                archivingDataSource: archivingDataSource),
            stopArchivingUseCase: DefaultStopArchivingUseCase(
                archivingDataSource: archivingDataSource),
            archivingStatusDataSource: archivingStatusDataSource)
        viewModel.setup()
        return (ArchiveScreenButton(viewModel: viewModel), viewModel)
    }

    public func makeArchivingButton(
        viewModel: ArchiveButtonViewModel
    ) -> some View {
        ArchiveScreenButton(viewModel: viewModel)
    }

    public func make(
        roomName: RoomName
    ) -> (view: some View, viewModel: ArchivesViewModel) {
        let viewModel = ArchivesViewModel(
            roomName: roomName,
            archivesRepository: archivesRepository,
            playRecordingUseCase: .init(
                archiveRecordingsRepository: archiveRecordingsRepository
            ) { _ in })
        return (ArchivesScreen(viewModel: viewModel), viewModel)
    }

    public func make(
        viewModel: ArchivesViewModel
    ) -> some View {
        ArchivesScreen(viewModel: viewModel)
    }
}
