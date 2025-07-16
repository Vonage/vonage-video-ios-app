//
//  Created by Vonage on 9/7/25.
//

import Foundation

public struct AudioDevice {
    public let id: String
    public let name: String
    public let portDescription: String

    public init(id: String, name: String, portDescription: String) {
        self.id = id
        self.name = name
        self.portDescription = portDescription
    }
}
