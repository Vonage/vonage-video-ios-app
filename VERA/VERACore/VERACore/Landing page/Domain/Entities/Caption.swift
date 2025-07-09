//
//  Created by Vonage on 9/7/25.
//

import Foundation

public struct Caption {
    public let id: String
    public let text: String
    public let timestamp: TimeInterval
    
    public init(id: String, text: String, timestamp: TimeInterval) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
    }
}
