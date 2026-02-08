//
//  Created by Vonage on 8/2/26.
//

import Foundation

public struct VonageCaption {
    public let name: String?
    public let text: String
    public let isFinal: Bool
    public let isRemote: Bool

    public init(
        name: String?,
        text: String,
        isFinal: Bool,
        isRemote: Bool
    ) {
        self.name = name
        self.text = text
        self.isFinal = isFinal
        self.isRemote = isRemote
    }
}
