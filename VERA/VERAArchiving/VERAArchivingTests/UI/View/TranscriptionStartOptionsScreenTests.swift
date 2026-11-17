//
//  Created by Vonage on 27/10/26.
//

import SwiftUI
import Testing
import VERAArchiving
import VERAArchivingTestHelpers
import VERADomain

@Suite("TranscriptionStartOptionsScreen tests")
@MainActor
struct TranscriptionStartOptionsScreenTests {

    @Test("Renders the start options of the given view model")
    func rendersStartOptions() {
        let viewModel = ArchiveButtonViewModel(
            kind: .transcription,
            sessionKeyProvider: DefaultSessionKeyHolder(),
            startArchivingUseCase: SpyStartArchivingUseCase(),
            stopArchivingUseCase: SpyStopArchivingUseCase(),
            archivingStatusDataSource: ArchivingStatusDataSourceSpy(),
            showAlert: { _ in })

        let renderer = ImageRenderer(
            content: TranscriptionStartOptionsScreen(viewModel: viewModel)
                .frame(width: 390, height: 300))

        #expect(renderer.cgImage != nil)
    }
}
