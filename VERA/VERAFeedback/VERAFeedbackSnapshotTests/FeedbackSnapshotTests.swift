//
//  Created by Vonage on 3/6/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERAFeedback

enum FeedbackFormSnapshotState {
    case validationErrors
    case filled
    case filledWithImage
}

@Suite("Feedback Snapshot Tests")
@MainActor
struct FeedbackSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "FeedbackView"

    // MARK: - Core UI Tests

    @Test(
        "FeedbackView - Basic Layouts",
        arguments: [
            ("compact-empty", UserInterfaceSizeClass.compact),
            ("iPad-empty", UserInterfaceSizeClass.regular),
        ])
    func basicLayouts(
        variant: String,
        horizontalSizeClass: UserInterfaceSizeClass
    ) throws {
        let sut = makeSUT(horizontalSizeClass: horizontalSizeClass)

        assertSnapshot(
            of: sut,
            as: layout(for: horizontalSizeClass),
            named: variant,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(variant)"
        )
    }

    @Test(
        "FeedbackView - iPhone Color Schemes",
        arguments: [
            ("iPhone-Dark", ColorScheme.dark)
        ])
    func iPhoneColorSchemes(
        schemeName: String,
        scheme: ColorScheme
    ) throws {
        let sut = makeSUT(horizontalSizeClass: .compact)
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    @Test(
        "FeedbackView - iPad Color Schemes",
        arguments: [
            ("iPad-Dark", ColorScheme.dark)
        ])
    func iPadColorSchemes(
        schemeName: String,
        scheme: ColorScheme
    ) throws {
        let sut = makeSUT(horizontalSizeClass: .regular)
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPadPro12_9)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    @Test(
        "FeedbackView - Form States",
        arguments: [
            ("validation-errors", FeedbackFormSnapshotState.validationErrors),
            ("filled-form", FeedbackFormSnapshotState.filled),
            ("filled-with-image", FeedbackFormSnapshotState.filledWithImage),
        ])
    func formStates(
        stateName: String,
        formState: FeedbackFormSnapshotState
    ) throws {
        let sut = makeSUT(horizontalSizeClass: .compact, formState: formState)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 390, height: 1400)),
            named: stateName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(stateName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(
        horizontalSizeClass: UserInterfaceSizeClass = .compact,
        formState: FeedbackFormSnapshotState? = nil
    ) -> AnyView {
        let viewModel = FeedbackSnapshotHelpers.makeFormViewModel()

        switch formState {
        case .validationErrors:
            viewModel.showValidationErrors = true
        case .filled:
            FeedbackSnapshotHelpers.fillRequiredTextFields(in: viewModel)
        case .filledWithImage:
            FeedbackSnapshotHelpers.fillRequiredTextFields(in: viewModel)
            FeedbackSnapshotHelpers.attachSampleImage(to: viewModel)
        case nil:
            break
        }

        return AnyView(
            FeedbackView(feedbackFormViewModel: viewModel)
                .environment(\.horizontalSizeClass, horizontalSizeClass)
        )
    }

    private func layout(for horizontalSizeClass: UserInterfaceSizeClass) -> Snapshotting<AnyView, UIImage> {
        switch horizontalSizeClass {
        case .regular:
            return .image(precision: 0.99, layout: .device(config: .iPadPro12_9))
        default:
            return .image(precision: 0.99, layout: .device(config: .iPhone13))
        }
    }
}
