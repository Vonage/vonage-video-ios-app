//
//  Created by Vonage on 18/7/25.
//

import Foundation

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    
    static func roomCredentialsError(_ errorMessage: String) -> AlertItem {
        AlertItem(
            title: "Connection Error",
            message: "Failed to get room credentials: \(errorMessage)"
        )
    }
}
