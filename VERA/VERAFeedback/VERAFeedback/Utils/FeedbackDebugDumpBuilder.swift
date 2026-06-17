//
//  Created by Vonage on 11/06/2026.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum FeedbackDebugDumpBuilder {

    private static let connectionCreationTimeFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Builds a diagnostic dump similar to the Android feedback implementation.
    static func debugDump(session: FeedbackSessionDebugInfo = .empty) -> String {
        """
        \n
        DEBUG INFO:
        \(platformDebugInfo())
        ===
        \(sessionDebugInfo(session))
        ===
        """
    }

    private static func platformDebugInfo() -> String {
        #if canImport(UIKit)
        """
        iOS Version: \(UIDevice.current.systemVersion)
        Device: Apple \(UIDevice.current.model)
        """
        #elseif canImport(AppKit)
        """
        macOS Version: \(macOSVersionString())
        Device: Apple \(Host.current().localizedName ?? "Mac")
        """
        #else
        "Platform: Unknown"
        #endif
    }

    #if canImport(AppKit)
    private static func macOSVersionString() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    #endif

    private static func sessionDebugInfo(_ session: FeedbackSessionDebugInfo) -> String {
        let creationTime = session.connectionCreationTime.map(connectionCreationTimeFormatter.string)
            ?? "null"

        return """
        Session: \(session.sessionId ?? "null")
        Connection: \(session.connectionId ?? "null")
        Connection creation time: \(creationTime)
        """
    }
}
