//
//  Created by Vonage on 4/8/25.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERACore

@Suite("GoodBye View UI Tests")
@MainActor
struct GoodByeViewUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "GoodBye"

    // MARK: - Core UI Tests

    @Test(
        "GoodBye View - Basic Layout",
        arguments: [
            ("without-archives", []),
            ("with-archives", makeArchives()),
        ])
    func basicLayout(variant: String, archives: [ArchiveUIData]) throws {
        let sut = makeSUT(archives: archives)

        snapshot(sut, named: "Default-\(variant)")
    }

    @Test(
        "GoodBye View - Size Classes",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13, []),
            ("iPad", ViewImageConfig.iPadPro12_9, []),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape), []),
            ("iPhone-with-archives", ViewImageConfig.iPhone13, makeArchives()),
            ("iPad-with-archives", ViewImageConfig.iPadPro12_9, makeArchives()),
            ("iPhoneLandscape-with-archives", ViewImageConfig.iPhone13(.landscape), makeArchives()),
        ])
    func sizeClasses(
        deviceName: String,
        config: ViewImageConfig,
        archives: [ArchiveUIData]
    ) throws {
        let sut = makeSUT(archives: archives)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }

    @Test(
        "GoodBye View - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light, []),
            ("Dark", ColorScheme.dark, []),
            ("Light-with-archives", ColorScheme.light, makeArchives()),
            ("Dark-with-archives", ColorScheme.dark, makeArchives()),
        ])
    func colorSchemes(
        schemeName: String,
        scheme: ColorScheme,
        archives: [ArchiveUIData]
    ) throws {
        let sut = makeSUT(archives: archives)
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
        "GoodBye View - Accessibility",
        arguments: [
            ("SmallText", ContentSizeCategory.extraSmall, []),
            ("LargeText", ContentSizeCategory.accessibilityExtraExtraExtraLarge, []),
            ("SmallText-with-archives", ContentSizeCategory.extraSmall, makeArchives()),
            ("LargeText-with-archives", ContentSizeCategory.accessibilityExtraExtraExtraLarge, makeArchives()),
        ])
    func accessibility(
        textName: String,
        textSize: ContentSizeCategory,
        archives: [ArchiveUIData]
    ) throws {
        let sut = makeSUT(archives: archives)
            .environment(\.sizeCategory, textSize)

        snapshot(sut, named: textName)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        archives: [ArchiveUIData] = []
    ) -> GoodByeView {
        GoodByeView(archives: archives) {
        } onReturnToLanding: {
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

func makeArchives() -> [ArchiveUIData] {
    [
        .init(
            id: .init(),
            title: "Recording 1",
            subtitle: "Started at: Mon, Aug 4 12:09 PM",
            isDownloadable: true),
        .init(
            id: .init(),
            title: "Recording 2",
            subtitle: "Started at: Mon, Aug 4 12:09 PM",
            isDownloadable: true),
        .init(
            id: .init(),
            title: "Recording 3",
            subtitle: "Started at: Mon, Aug 4 12:09 PM",
            isDownloadable: false),
    ]
}

// MARK: - Component Tests

@Suite("GoodByeView Components")
@MainActor
struct GoodByeViewComponentTests {

    private let isRecording = false
    private let snapshotPrefix = "GoodBye"

    @Test(
        "Layout Components",
        arguments: [
            ("Horizontal", 800, 400),
            ("Vertical", 375, 600),
        ])
    func layoutComponents(layoutName: String, width: CGFloat, height: CGFloat) throws {
        let view: AnyView

        switch layoutName {
        case "Horizontal":
            view = AnyView(
                HorizontalGoodByeContentView(
                    archives: [],
                    onReenter: {
                    },
                    onReturnToLanding: {
                    }))
        case "Vertical":
            view = AnyView(
                VerticalGoodByeContentView(
                    archives: [],
                    onReenter: {
                    },
                    onReturnToLanding: {
                    }))
        default:
            return
        }

        let framedView =
            view
            .frame(width: width, height: height)
            .background(Color(.systemBackground))

        assertSnapshot(
            of: framedView,
            as: .image(precision: 0.99, layout: .fixed(width: width, height: height)),
            named: layoutName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(layoutName)"
        )
    }
}
