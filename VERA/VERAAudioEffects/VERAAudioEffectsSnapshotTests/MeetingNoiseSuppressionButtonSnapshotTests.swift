//
//  Created by Vonage on 12/3/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERADomain

@testable import VERAAudioEffects

@Suite("MeetingNoiseSuppressionButtonContainer UI Tests")
@MainActor
struct MeetingNoiseSuppressionButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "MeetingNoiseSuppressionButtonContainer"

    // MARK: - Core UI Tests

    @Test(
        "MeetingNoiseSuppressionButtonContainer - Color Schemes",
        arguments: [
            ("Light-disabled", ColorScheme.light, NoiseSuppressionState.disabled),
            ("Light-enabled", ColorScheme.light, NoiseSuppressionState.enabled),
            ("Dark-disabled", ColorScheme.dark, NoiseSuppressionState.disabled),
            ("Dark-enabled", ColorScheme.dark, NoiseSuppressionState.enabled),
        ])
    func colorSchemes(
        schemeName: String,
        scheme: ColorScheme,
        state: NoiseSuppressionState
    ) throws {
        let sut = makeSUT(state: state)
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(
        state: NoiseSuppressionState = .disabled
    ) -> some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()

            VStack {
                Spacer()
                MeetingNoiseSuppressionButtonContainer(
                    viewModel: makeViewModel(state: state)
                )
            }
            .padding(.bottom, 16)
        }
    }

    private func makeViewModel(state: NoiseSuppressionState) -> MeetingNoiseSuppressionViewModel {
        let viewModel = MeetingNoiseSuppressionViewModel(
            getCurrentPublisher: { throw NSError(domain: "Test", code: 0) },
            disableNoiseSuppressionUseCase: DisableUseCaseSpy(),
            enableNoiseSuppressionUseCase: EnableUseCaseSpy()
        )
        viewModel.state = state
        return viewModel
    }

    private func snapshot<V: View>(
        _ view: V,
        named name: String
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: name,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(name)"
        )
    }
}
