//
//  Created by Vonage on 5/3/26.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERASettings

@Suite("Settings Meeting Room Button Snapshot Tests")
@MainActor
struct SettingsMeetingRoomButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "SettingsMeetingRoomButton"

    // MARK: - Basic Layouts Tests

    @Test(
        "Basic Layouts",
        arguments: [
            ("iPhone13", ViewImageConfig.iPhone13),
            ("iPadPro12_9", ViewImageConfig.iPadPro12_9(.portrait)),
        ])
    func basicLayouts(
        deviceName: String,
        config: ViewImageConfig
    ) async throws {
        let sut = makeSUT()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }

    // MARK: - Color Schemes Tests

    @Test(
        "Color Schemes",
        arguments: [
            ("light", ColorScheme.light),
            ("dark", ColorScheme.dark),
        ])
    func colorSchemes(
        schemeName: String,
        colorScheme: ColorScheme
    ) async throws {
        let sut = makeSUT(colorScheme: colorScheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Scale Factors Tests

    @Test(
        "Scale Factors",
        arguments: [
            ("small", 0.8),
            ("normal", 1.0),
            ("large", 1.2),
        ])
    func scaleFactors(
        scaleName: String,
        scale: CGFloat
    ) async throws {
        let sut = ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple, .pink]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                SettingsMeetingRoomButton {
                    // Empty action for testing
                }
                .scaleEffect(scale)
                .padding(.bottom, 16)
            }
        }
        .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: AnyView(sut),
            as: .image(precision: 0.99, layout: .fixed(width: 200, height: 200)),
            named: scaleName,
            record: isRecording,
            testName: "\(snapshotPrefix)_scale_\(scaleName)"
        )
    }

    // MARK: - Landscape Orientation Tests

    @Test("Landscape Orientation")
    func landscapeOrientation() async throws {
        let sut = makeSUT()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13(.landscape))),
            named: "landscape",
            record: isRecording,
            testName: "\(snapshotPrefix)_landscape"
        )
    }

    // MARK: - Both Buttons Comparison

    @Test(
        "Both Buttons Comparison",
        arguments: [
            ("comparison_light", ColorScheme.light),
            ("comparison_dark", ColorScheme.dark),
        ])
    func bothButtonsComparison(
        comparisonName: String,
        colorScheme: ColorScheme
    ) async throws {
        let sut = ZStack {
            Color.gray
                .ignoresSafeArea()

            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    SettingsWaitingRoomButton {
                        SettingsView(viewModel: .preview)
                    }
                    Text("Waiting Room")
                        .font(.caption)
                        .foregroundColor(.primary)
                }

                VStack(spacing: 12) {
                    SettingsMeetingRoomButton {
                        // Empty action for testing
                    }
                    Text("Meeting Room")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .environment(\.colorScheme, colorScheme)

        assertSnapshot(
            of: AnyView(sut),
            as: .image(precision: 0.99, layout: .fixed(width: 300, height: 400)),
            named: comparisonName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(comparisonName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(
        colorScheme: ColorScheme = .dark
    ) -> some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()

            VStack {
                Spacer()
                SettingsMeetingRoomButton()
                    .padding(.bottom, 16)
            }
        }
        .environment(\.colorScheme, colorScheme)
    }
}
