//
//  Created by Vonage on 4/8/25.
//

import Foundation

public struct AlertItem: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let okAction: String?
    public let cancelAction: String?
    public let onConfirm: (@MainActor () -> Void)?

    public init(
        title: String,
        message: String,
        onConfirm: (@MainActor () -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.onConfirm = onConfirm
        self.okAction = "OK"
        self.cancelAction = nil
    }

    public init(
        title: String,
        message: String,
        okAction: String,
        cancelAction: String,
        onConfirm: (@MainActor () -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.onConfirm = onConfirm
        self.okAction = okAction
        self.cancelAction = cancelAction
    }

    public static func cameraPermissionAlert(onConfirm: @escaping @MainActor () -> Void) -> AlertItem {
        getAlertWithText(message: "Please review camera permissions in settings.", onConfirm: onConfirm)
    }

    public static func microphonePermissionAlert(onConfirm: @escaping @MainActor () -> Void) -> AlertItem {
        getAlertWithText(message: "Please review microphone permissions in settings.", onConfirm: onConfirm)
    }

    public static func getAlertWithText(message: String, onConfirm: @escaping @MainActor () -> Void) -> AlertItem {
        AlertItem(
            title: "Check Settings",
            message: message,
            okAction: "Go to settings",
            cancelAction: "Cancel",
            onConfirm: onConfirm
        )
    }

    public static func genericError(
        _ errorMessage: String,
        onConfirm: (@MainActor () -> Void)? = nil
    ) -> AlertItem {
        AlertItem(
            title: "Error",
            message: errorMessage,
            onConfirm: onConfirm
        )
    }

    public static func roomCredentialsError(
        _ errorMessage: String,
        onConfirm: (@MainActor () -> Void)? = nil
    ) -> AlertItem {
        AlertItem(
            title: "Connection Error",
            message: "Failed to get room credentials: \(errorMessage)",
            onConfirm: onConfirm
        )
    }

    public static func goodbyeError(
        _ errorMessage: String,
        onConfirm: (@MainActor () -> Void)? = nil
    ) -> AlertItem {
        AlertItem(
            title: "Error",
            message: "Failed to get room archives: \(errorMessage)",
            onConfirm: onConfirm
        )
    }

    /// Shared with ``RoomCredentialsError/errorDescription`` so the user sees the same wording whether the
    /// expired session key was caught from an incoming deep link or from joining the meeting.
    public static var expiredLinkMessage: String {
        String(localized: "This meeting link has expired.", bundle: .veraDomain)
    }

    public static func expiredLinkError(onConfirm: (@MainActor () -> Void)? = nil) -> AlertItem {
        AlertItem(
            title: String(localized: "Link Expired", bundle: .veraDomain),
            message: expiredLinkMessage,
            onConfirm: onConfirm
        )
    }

    public static func downloadError(
        _ errorMessage: String,
        onConfirm: (@MainActor () -> Void)? = nil
    ) -> AlertItem {
        AlertItem(
            title: "Error",
            message: "Failed to download file: \(errorMessage)",
            onConfirm: onConfirm
        )
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.message == rhs.message
    }
}
