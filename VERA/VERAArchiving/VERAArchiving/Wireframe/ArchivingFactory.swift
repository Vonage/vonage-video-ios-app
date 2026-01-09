//
//  Created by Vonage on 9/1/26.
//

import SwiftUI
import VERADomain

public final class ArchivingFactory {

    private let archivesRepository: ArchivesRepository
    private let archiveRecordingsRepository: ArchiveRecordingsRepository

    public init(
        archivesRepository: ArchivesRepository,
        archiveRecordingsRepository: ArchiveRecordingsRepository
    ) {
        self.archivesRepository = archivesRepository
        self.archiveRecordingsRepository = archiveRecordingsRepository
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
