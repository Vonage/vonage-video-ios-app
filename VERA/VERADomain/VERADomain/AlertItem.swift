//
//  Created by Vonage on 4/8/25.
//

import Foundation

public struct AlertItem: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let onConfirm: (() -> Void)?

    public init(
        title: String,
        message: String,
        onConfirm: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.onConfirm = onConfirm
    }

    public static func genericError(
        _ errorMessage: String,
        onConfirm: (() -> Void)? = nil
    ) -> AlertItem {
        AlertItem(
            title: "Error",
            message: errorMessage,
            onConfirm: onConfirm
        )
    }

    public static func roomCredentialsError(
        _ errorMessage: String,
        onConfirm: (() -> Void)? = nil
    ) -> AlertItem {
        AlertItem(
            title: "Connection Error",
            message: "Failed to get room credentials: \(errorMessage)",
            onConfirm: onConfirm
        )
    }

    public static func goodbyeError(
        _ errorMessage: String,
        onConfirm: (() -> Void)? = nil
    ) -> AlertItem {
        AlertItem(
            title: "Error",
            message: "Failed to get room archives: \(errorMessage)",
            onConfirm: onConfirm
        )
    }

    public static func downloadError(
        _ errorMessage: String,
        onConfirm: (() -> Void)? = nil
    ) -> AlertItem {
        AlertItem(
            title: "Error",
            message: "Failed to download recording: \(errorMessage)",
            onConfirm: onConfirm
        )
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.message == rhs.message
    }
}
