//
//  Created by Vonage on 7/8/25.
//

import Foundation

public class Participant {
    public let id: String
    public let name: String
    public let renderer: any VideoRenderable

    public init(id: String, name: String, renderer: any VideoRenderable) {
        self.id = id
        self.name = name
        self.renderer = renderer
    }
}
