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
            ("without-archives")
        ])
    func basicLayout(variant: String) throws {
        let sut = makeSUT()

        snapshot(sut, named: "Default-\(variant)")
    }

    @Test(
        "GoodBye View - Size Classes",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPad", ViewImageConfig.iPadPro12_9),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
        ])
    func sizeClasses(
        deviceName: String,
        config: ViewImageConfig
    ) throws {
        let sut = makeSUT()

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
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(
        schemeName: String,
        scheme: ColorScheme
    ) throws {
        let sut = makeSUT()
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
            ("SmallText", ContentSizeCategory.extraSmall),
            ("LargeText", ContentSizeCategory.accessibilityExtraExtraExtraLarge),
        ])
    func accessibility(
        textName: String,
        textSize: ContentSizeCategory
    ) throws {
        let sut = makeSUT()
            .environment(\.sizeCategory, textSize)

        snapshot(sut, named: textName)
    }

    // MARK: - Test Helpers

    private func makeSUT() -> GoodByeView<AnyView> {
        GoodByeView {
            AnyView(Color.clear)
        } onReenter: {
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
                    additionalContentView: {},
                    onReenter: {},
                    onReturnToLanding: {}))
        case "Vertical":
            view = AnyView(
                VerticalGoodByeContentView(
                    additionalContentView: {},
                    onReenter: {},
                    onReturnToLanding: {}))
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
