//
//  Created by Vonage on 5/2/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERACaptions
import VERADomain

@Suite("Captions UI Tests")
@MainActor
struct VERACaptionsSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "Captions"

    // MARK: - Core UI Tests

    @Test(
        "Captions View - Basic Layout",
        arguments: [
            ("single-caption", [CaptionItem.sample1]),
            ("multiple-captions", CaptionItem.sampleMessages),
            ("long-text", [CaptionItem.sampleLongText]),
        ])
    func basicLayout(variant: String, captions: [CaptionItem]) throws {
        let sut = makeSUT(captions: captions)

        snapshot(sut, named: "Default-\(variant)")
    }

    @Test(
        "Captions View - Size Classes",
        arguments: [
            ("iPhone-with-captions", ViewImageConfig.iPhone13, CaptionItem.sampleMessages),
            ("iPad-with-captions", ViewImageConfig.iPadPro12_9, CaptionItem.sampleMessages),
            ("iPhoneLandscape-with-captions", ViewImageConfig.iPhone13(.landscape), CaptionItem.sampleMessages),
        ])
    func sizeClasses(
        deviceName: String,
        config: ViewImageConfig,
        captions: [CaptionItem]
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
        "Captions View - Color Schemes",
        arguments: [
            ("Light-with-captions", ColorScheme.light, CaptionItem.sampleMessages),
            ("Dark-with-captions", ColorScheme.dark, CaptionItem.sampleMessages),
        ])
    func colorSchemes(
        schemeName: String,
        scheme: ColorScheme,
        captions: [CaptionItem]
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
        "Captions View - Accessibility",
        arguments: [
            ("SmallText-with-captions", ContentSizeCategory.extraSmall, CaptionItem.sampleMessages),
            (
                "LargeText-with-captions", ContentSizeCategory.accessibilityExtraExtraExtraLarge,
                CaptionItem.sampleMessages
            ),
        ])
    func accessibility(
        textName: String,
        textSize: ContentSizeCategory,
        captions: [CaptionItem]
    ) throws {
        let sut = makeSUT(captions: captions)
            .environment(\.sizeCategory, textSize)

        snapshot(sut, named: textName)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        captions: [CaptionItem] = CaptionItem.sampleMessages
    ) -> some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()

            CaptionsView(captions: captions)
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

extension CaptionItem {
    static let sample1 = CaptionItem(
        speakerName: "Alice",
        text: "Hello everyone, welcome to the meeting!"
    )

    static let sample2 = CaptionItem(
        speakerName: "Bob",
        text: "Thanks for joining.",
        timestamp: Date().addingTimeInterval(-1)
    )

    static let sample3 = CaptionItem(
        speakerName: "Charlie",
        text: "Let's get started!",
        timestamp: Date().addingTimeInterval(-2)
    )

    static let sampleLongText = CaptionItem(
        speakerName: "David",
        text: """
            This is a very long caption that demonstrates how the view handles text 
            that wraps across multiple lines and maintains good readability even with extended content.
            """
    )

    static let sampleMessages: [CaptionItem] = [
        sample1,
        sample2,
        sample3,
    ]
}
