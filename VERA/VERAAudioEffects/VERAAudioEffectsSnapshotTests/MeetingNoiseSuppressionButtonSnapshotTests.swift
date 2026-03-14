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
        "MeetingNoiseSuppressionButtonContainer - Basic Layout",
        arguments: [
            ("disabled", NoiseSuppressionState.disabled),
            ("enabled", NoiseSuppressionState.enabled),
        ])
    func basicLayout(variant: String, state: NoiseSuppressionState) throws {
        let sut = makeSUT(state: state)

        snapshot(sut, named: "Default-\(variant)")
    }

    @Test(
        "MeetingNoiseSuppressionButtonContainer - Size Classes",
        arguments: [
            ("iPhone-disabled", ViewImageConfig.iPhone13, NoiseSuppressionState.disabled),
            ("iPhone-enabled", ViewImageConfig.iPhone13, NoiseSuppressionState.enabled),
            ("iPad-disabled", ViewImageConfig.iPadPro12_9, NoiseSuppressionState.disabled),
            ("iPad-enabled", ViewImageConfig.iPadPro12_9, NoiseSuppressionState.enabled),
            ("iPhoneLandscape-enabled", ViewImageConfig.iPhone13(.landscape), NoiseSuppressionState.enabled),
        ])
    func sizeClasses(
        deviceName: String,
        config: ViewImageConfig,
        state: NoiseSuppressionState
    ) throws {
        let sut = makeSUT(state: state)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }

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

    @Test("MeetingNoiseSuppressionButtonContainer - Accessibility")
    func accessibility() throws {
        let sut = makeSUT(state: .enabled)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

        snapshot(sut, named: "Accessibility-XXXL")
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
