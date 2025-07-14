//
//  LandingPageViewUITests.swift
//  VERACoreSnapshotTests
//
//  Created by Vonage on 7/11/25.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERACore

@Suite("Landing Page View UI Tests")
@MainActor
struct LandingPageViewUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots

    // MARK: - Test Helpers

    private func makeLandingPageView() -> LandingPageView {
        return LandingPageView(
            onHandleNewRoom: {},
            onJoinRoom: { _ in },
            onNavigateToWaitingRoom: { _ in }
        )
    }

    private func snapshot(_ view: some View, named: String) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: named,
            record: isRecording
        )
    }

    // MARK: - Core UI Tests

    @Test("Landing Page View - Basic Layout")
    func basicLayout() throws {
        snapshot(makeLandingPageView(), named: "Default")
    }

    @Test(
        "Landing Page View - Size Classes",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPad", ViewImageConfig.iPadPro12_9),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
        ])
    func sizeClasses(deviceName: String, config: ViewImageConfig) throws {
        let view = makeLandingPageView()

        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording
        )
    }

    @Test(
        "Landing Page View - Color Schemes",
        arguments: [("Light", ColorScheme.light), ("Dark", ColorScheme.dark)])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let view = makeLandingPageView()
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: schemeName,
            record: isRecording
        )
    }

    @Test(
        "Landing Page View - Accessibility",
        arguments: [
            ("SmallText", ContentSizeCategory.extraSmall),
            ("LargeText", ContentSizeCategory.accessibilityExtraExtraExtraLarge),
        ])
    func accessibility(textName: String, textSize: ContentSizeCategory) throws {
        let view = makeLandingPageView()
            .environment(\.sizeCategory, textSize)

        snapshot(view, named: textName)
    }
}

// MARK: - Component Tests

@Suite("Landing Page Components")
@MainActor
struct LandingPageComponentTests {

    private let isRecording = false

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
                HorizontalLandingContentView(onHandleNewRoom: {}, onJoinRoom: { _ in })
            )
        case "Vertical":
            view = AnyView(
                VerticalLandingContentView(onHandleNewRoom: {}, onJoinRoom: { _ in })
            )
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
            record: isRecording
        )
    }
}
