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

    /// Builds a diagnostic dump similar to the Android feedback implementation.
    @MainActor
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

    @MainActor
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
        let creationTime =
            session.connectionCreationTime.map { date in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return formatter.string(from: date)
            } ?? "null"

        return """
            Session: \(session.sessionId ?? "null")
            Connection: \(session.connectionId ?? "null")
            Connection creation time: \(creationTime)
            """
    }
}
