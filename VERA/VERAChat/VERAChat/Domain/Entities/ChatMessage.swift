//
//  Created by Vonage on 10/10/25.
//

import Foundation

public struct ChatMessage {
    public let username: String
    public let message: String
    public let date: Date

    public init(username: String, message: String, date: Date) {
        self.username = username
        self.message = message
        self.date = date
    }
}
