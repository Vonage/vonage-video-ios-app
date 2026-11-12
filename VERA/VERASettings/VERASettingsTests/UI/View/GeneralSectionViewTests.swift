//
//  Created by Vonage on 27/10/26.
//

import SwiftUI
import Testing

@testable import VERASettings

@Suite("GeneralSectionView tests")
@MainActor
struct GeneralSectionViewTests {

    @Test(
        "Renders the AI summary default in every layout and call context",
        arguments: [
            (false, false),
            (true, false),
            (false, true),
            (true, true),
        ])
    func rendersTranscriptionSummaryToggle(isCompactLayout: Bool, isInActiveCall: Bool) {
        let viewModel = SettingsViewModel(
            repository: MockSettingsRepository(),
            showsTranscriptionSummary: true)

        let renderer = ImageRenderer(
            content: GeneralSectionView(
                viewModel: viewModel,
                isInActiveCall: isInActiveCall,
                isCompactLayout: isCompactLayout
            )
            .frame(width: 390, height: 300))

        #expect(renderer.cgImage != nil)
        #expect(viewModel.settingsPreference.transcriptionSummaryEnabled)
    }
}
