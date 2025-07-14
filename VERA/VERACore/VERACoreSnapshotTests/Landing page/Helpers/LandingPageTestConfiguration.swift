//
//  LandingPageTestConfiguration.swift
//  VERACoreSnapshotTests
//
//  Created by Vonage on 7/11/25.
//

import Foundation
import SnapshotTesting
import SwiftUI
import VERACore
import XCTest

// MARK: - Test Configuration

enum LandingPageTestConfiguration {

    // MARK: - Snapshot Configuration

    /// Set to true to record new snapshots instead of comparing
    static let isRecordingSnapshots = false

    /// Default timeout for async operations in tests
    static let defaultTimeout: TimeInterval = 5.0

    /// Standard test devices for snapshot testing
    static let testDevices: [(String, ViewImageConfig)] = [
        ("iPhone13Mini", .iPhone13Mini),
        ("iPhone13", .iPhone13),
        ("iPhone13Pro", .iPhone13Pro),
        ("iPhone13ProMax", .iPhone13ProMax),
        ("iPadMini", .iPadMini),
        ("iPad", .iPad10_2),
        ("iPadPro11", .iPadPro11),
        ("iPadPro12_9", .iPadPro12_9),
    ]

    // MARK: - Accessibility Test Configurations

    static let accessibilityTextSizes: [(String, ContentSizeCategory)] = [
        ("ExtraSmall", .extraSmall),
        ("Small", .small),
        ("Medium", .medium),
        ("Large", .large),
        ("ExtraLarge", .extraLarge),
        ("ExtraExtraLarge", .extraExtraLarge),
        ("ExtraExtraExtraLarge", .extraExtraExtraLarge),
        ("AccessibilityMedium", .accessibilityMedium),
        ("AccessibilityLarge", .accessibilityLarge),
        ("AccessibilityExtraLarge", .accessibilityExtraLarge),
        ("AccessibilityExtraExtraLarge", .accessibilityExtraExtraLarge),
        ("AccessibilityExtraExtraExtraLarge", .accessibilityExtraExtraExtraLarge),
    ]

    // MARK: - Test Data

    struct MockData {
        static let validRoomNames = [
            "test-room",
            "meeting-room-123",
            "daily-standup",
            "team-sync",
            "project-review",
        ]

        static let invalidRoomNames = [
            "",
            " ",
            "room with spaces",
            "room@with#special!chars",
            "verylongroomnamethatexceedsmaximumlength",
        ]
    }

    // MARK: - Helper Methods

    /// Creates a standard test view for consistent testing
    static func createTestView(
        onHandleNewRoom: @escaping () -> Void = {},
        onJoinRoom: @escaping (String) -> Void = { _ in },
        onNavigateToWaitingRoom: @escaping (String) -> Void = { _ in }
    ) -> LandingPageView {
        return LandingPageView(
            onHandleNewRoom: onHandleNewRoom,
            onJoinRoom: onJoinRoom,
            onNavigateToWaitingRoom: onNavigateToWaitingRoom
        )
    }

    /// Creates a test view with specific environment settings
    static func createTestViewWithEnvironment(
        horizontalSizeClass: UserInterfaceSizeClass? = .regular,
        verticalSizeClass: UserInterfaceSizeClass? = .regular,
        colorScheme: ColorScheme = .light,
        contentSizeCategory: ContentSizeCategory = .medium
    ) -> some View {
        createTestView()
            .environment(\.horizontalSizeClass, horizontalSizeClass)
            .environment(\.verticalSizeClass, verticalSizeClass)
            .environment(\.colorScheme, colorScheme)
            .environment(\.sizeCategory, contentSizeCategory)
    }
}

// MARK: - Test Accessibility Identifiers

enum LandingPageAccessibilityIdentifiers {
    static let landingPageView = "LandingPageView"
    static let banner = "Banner"
    static let landingPageWelcome = "LandingPageWelcome"
    static let roomJoinContainer = "RoomJoinContainer"
    static let newRoomButton = "NewRoomButton"
    static let joinButton = "JoinButton"
    static let roomNameTextField = "RoomNameTextField"
    static let horizontalContentView = "HorizontalLandingContentView"
    static let verticalContentView = "VerticalLandingContentView"
    static let githubRepoButton = "GHRepoButton"
    static let bannerLogo = "BannerLogo"
    static let bannerDateTime = "BannerDateTime"
    static let bannerLinks = "BannerLinks"
}

// MARK: - Test Expectations Helper

class TestExpectationsHelper {

    /// Creates an expectation for navigation events
    static func navigationExpectation(description: String) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: description)
        expectation.expectedFulfillmentCount = 1
        return expectation
    }

    /// Creates an expectation for UI state changes
    static func uiStateChangeExpectation(description: String) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: description)
        expectation.expectedFulfillmentCount = 1
        return expectation
    }

    /// Creates an expectation for user interactions
    static func userInteractionExpectation(description: String) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: description)
        expectation.expectedFulfillmentCount = 1
        return expectation
    }
}

// MARK: - Mock Callbacks

struct MockCallbacks {
    var onHandleNewRoom: () -> Void
    var onJoinRoom: (String) -> Void
    var onNavigateToWaitingRoom: (String) -> Void

    static func create(
        newRoomAction: @escaping () -> Void = {},
        joinRoomAction: @escaping (String) -> Void = { _ in },
        navigationAction: @escaping (String) -> Void = { _ in }
    ) -> MockCallbacks {
        return MockCallbacks(
            onHandleNewRoom: newRoomAction,
            onJoinRoom: joinRoomAction,
            onNavigateToWaitingRoom: navigationAction
        )
    }
}

// MARK: - Test Performance Metrics

enum TestPerformanceMetrics {
    static let viewCreationMetric = "View Creation Time"
    static let layoutMetric = "Layout Performance"
    static let renderingMetric = "Rendering Performance"
    static let interactionMetric = "User Interaction Response Time"

    /// Standard performance thresholds
    struct Thresholds {
        static let viewCreation: TimeInterval = 0.1
        static let layout: TimeInterval = 0.05
        static let rendering: TimeInterval = 0.1
        static let interaction: TimeInterval = 0.2
    }
}
