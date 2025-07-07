//
//  SnapshotTestHelpers.swift
//  VERACoreSnapshotTests
//
//  Created by Ivan Ornes on 7/7/25.
//

import SnapshotTesting
import SwiftUI
import Testing

// MARK: - iOS Snapshot Testing Helpers

/// Helper for testing SwiftUI views 
enum SnapshotTestHelper {
    
    /// Test a SwiftUI view with size that fits
    static func assertViewSnapshot<V: View>(
        _ view: V,
        testName: String? = nil,
        record: Bool = false,
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            named: testName,
            record: record,
            file: file,
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
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        assertSnapshot(
            of: view,
            as: .image(layout: .fixed(width: width, height: height)),
            named: testName,
            record: record,
            file: file,
            testName: function,
            line: line
        )
    }
    
    /// Test a view with light and dark mode variants
    static func assertViewSnapshotsWithColorSchemes<V: View>(
        _ view: V,
        testName: String? = nil,
        record: Bool = false,
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        // Light mode
        assertSnapshot(
            of: view.preferredColorScheme(.light),
            as: .image(layout: .sizeThatFits),
            named: testName.map { "\($0)_light" } ?? "light",
            record: record,
            file: file,
            testName: function,
            line: line
        )

        // Dark mode
        assertSnapshot(
            of: view.preferredColorScheme(.dark),
            as: .image(layout: .sizeThatFits),
            named: testName.map { "\($0)_dark" } ?? "dark",
            record: record,
            file: file,
            testName: function,
            line: line
        )
    }
}
