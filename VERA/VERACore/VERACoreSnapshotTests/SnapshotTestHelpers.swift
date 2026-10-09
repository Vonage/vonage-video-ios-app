//
//  Created by Vonage on 7/7/25.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERACore

// MARK: - iOS Snapshot Testing Helpers

/// Helper for testing SwiftUI views
enum SnapshotTestHelper {

    /// Fixed rendering fixtures, independent of the app bundle and SDK dependency versions.
    /// Keep these values unchanged when either released version is bumped.
    static var footerVersions: AppVersionDisplay {
        AppVersionDisplay(appVersion: "1.3", sdkVersion: "2.35.1")
    }

    /// Test a SwiftUI view with size that fits
    static func assertViewSnapshot<V: View>(
        _ view: V,
        testName: String? = nil,
        record: Bool = false,
        filePath: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line
    ) {
        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            named: testName,
            record: record,
            file: filePath,
            testName: function,
            line: line
        )
    }

    /// Test a SwiftUI view with fixed size
    static func assertViewSnapshot<V: View>(
        _ view: V,
        width: CGFloat,
        height: CGFloat,
        testName: String? = nil,
        record: Bool = false,
        filePath: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line
    ) {
        assertSnapshot(
            of: view,
            as: .image(layout: .fixed(width: width, height: height)),
            named: testName,
            record: record,
            file: filePath,
            testName: function,
            line: line
        )
    }

    /// Test a view with light and dark mode variants
    static func assertViewSnapshotsWithColorSchemes<V: View>(
        _ view: V,
        testName: String? = nil,
        record: Bool = false,
        filePath: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line
    ) {
        // Light mode
        assertSnapshot(
            of: view.preferredColorScheme(.light),
            as: .image(layout: .sizeThatFits),
            named: testName.map { "\($0)_light" } ?? "light",
            record: record,
            file: filePath,
            testName: function,
            line: line
        )

        // Dark mode
        assertSnapshot(
            of: view.preferredColorScheme(.dark),
            as: .image(layout: .sizeThatFits),
            named: testName.map { "\($0)_dark" } ?? "dark",
            record: record,
            file: filePath,
            testName: function,
            line: line
        )
    }
}
