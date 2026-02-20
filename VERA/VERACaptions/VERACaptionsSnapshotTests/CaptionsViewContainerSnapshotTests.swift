//
//  Created by Vonage on 20/02/2026.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERACaptions
import VERADomain

@Suite("CaptionsViewContainer UI Tests")
@MainActor
struct CaptionsViewContainerSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "CaptionsViewContainer"

    // MARK: - Core UI Tests

    @Test(
        "CaptionsViewContainer - Basic Layout",
        arguments: [
            ("empty", [UICaptionItem]()),
            ("single-caption", [UICaptionItem.sampleAlice]),
            ("multiple-captions", UICaptionItem.sampleMessages),
            ("long-text", [UICaptionItem.sampleLongText]),
            ("scrollable-captions", UICaptionItem.sampleScrollableMessages),
        ])
    func basicLayout(variant: String, captions: [UICaptionItem]) throws {
        let sut = makeSUT(captions: captions)

        snapshot(sut, named: "Default-\(variant)")
    }

    @Test(
        "CaptionsViewContainer - Size Classes",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13, UICaptionItem.sampleMessages),
            ("iPad", ViewImageConfig.iPadPro12_9, UICaptionItem.sampleMessages),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape), UICaptionItem.sampleMessages),
        ])
    func sizeClasses(
        deviceName: String,
        config: ViewImageConfig,
        captions: [UICaptionItem]
    ) throws {
        let sut = makeSUT(captions: captions)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }

    @Test(
        "CaptionsViewContainer - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light, UICaptionItem.sampleMessages),
            ("Dark", ColorScheme.dark, UICaptionItem.sampleMessages),
        ])
    func colorSchemes(
        schemeName: String,
        scheme: ColorScheme,
        captions: [UICaptionItem]
    ) throws {
        let sut = makeSUT(captions: captions)
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
        "CaptionsViewContainer - Accessibility",
        arguments: [
            ("SmallText", ContentSizeCategory.extraSmall, UICaptionItem.sampleMessages),
            (
                "LargeText", ContentSizeCategory.accessibilityExtraExtraExtraLarge,
                UICaptionItem.sampleMessages
            ),
        ])
    func accessibility(
        textName: String,
        textSize: ContentSizeCategory,
        captions: [UICaptionItem]
    ) throws {
        let sut = makeSUT(captions: captions)
            .environment(\.sizeCategory, textSize)

        snapshot(sut, named: textName)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        captions: [UICaptionItem] = UICaptionItem.sampleMessages
    ) -> some View {
        let viewModel = CaptionsViewModel()
        viewModel.captions = captions

        return ZStack {
            Color.gray
                .ignoresSafeArea()

            VStack {
                Spacer()
                CaptionsViewContainer(viewModel: viewModel)
            }
        }
    }

    private func snapshot(
        _ view: some View,
        named: String,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}

// MARK: - Sample Data

extension UICaptionItem {
    static let sampleAlice = UICaptionItem(
        caption: CaptionItem(
            speakerName: "Alice",
            text: "Hello everyone, welcome to the meeting!"
        )
    )

    static let sampleBob = UICaptionItem(
        caption: CaptionItem(
            speakerName: "Bob",
            text: "Thanks for joining.",
            timestamp: Date().addingTimeInterval(-1)
        )
    )

    static let sampleCharlie = UICaptionItem(
        caption: CaptionItem(
            speakerName: "Charlie",
            text: "Let's get started!",
            timestamp: Date().addingTimeInterval(-2)
        )
    )

    static let sampleDiana = UICaptionItem(
        caption: CaptionItem(
            speakerName: "Diana",
            text: "I have a few items to cover.",
            timestamp: Date().addingTimeInterval(-3)
        )
    )

    static let sampleAlice2 = UICaptionItem(
        caption: CaptionItem(
            speakerName: "Alice",
            text: "Great, Diana please go first.",
            timestamp: Date().addingTimeInterval(-4)
        )
    )

    static let sampleDiana2 = UICaptionItem(
        caption: CaptionItem(
            speakerName: "Diana",
            text: "Thanks! The first thing is the new feature release.",
            timestamp: Date().addingTimeInterval(-5)
        )
    )

    static let sampleLongText = UICaptionItem(
        caption: CaptionItem(
            speakerName: "David",
            text: """
                This is a very long caption that demonstrates how the view handles text \
                that wraps across multiple lines and maintains good readability even with extended content.
                """
        )
    )

    static let sampleMessages: [UICaptionItem] = [
        sampleAlice,
        sampleBob,
        sampleCharlie,
    ]

    static let sampleScrollableMessages: [UICaptionItem] = [
        sampleAlice,
        sampleBob,
        sampleCharlie,
        sampleDiana,
        sampleAlice2,
        sampleDiana2,
    ]
}
