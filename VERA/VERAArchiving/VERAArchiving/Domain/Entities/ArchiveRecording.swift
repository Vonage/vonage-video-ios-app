//
//  Created by Vonage on 6/8/25.
//

import Foundation

public struct ArchiveRecording: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }
}
