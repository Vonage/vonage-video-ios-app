//
//  Created by Vonage on 4/8/25.
//

import Foundation

public struct AlertItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    public static func genericError(_ errorMessage: String) -> AlertItem {
        AlertItem(
            title: "Error",
            message: errorMessage
        )
    }
    
    public static func roomCredentialsError(_ errorMessage: String) -> AlertItem {
        AlertItem(
            title: "Connection Error",
            message: "Failed to get room credentials: \(errorMessage)"
        )
    }
    
    public static func goodbyeError(_ errorMessage: String) -> AlertItem {
        AlertItem(
            title: "Error",
            message: "Failed to get room archives: \(errorMessage)"
        )
    }
}
