//
//  Created by Vonage on 8/6/26.
//

import Foundation

struct E2ESession {
    let roomName: String
    let sessionId: String
    let sessionKey: String
    let applicationId: String
}

struct E2EArchive {
    let id: String
    let name: String
    let sessionKey: String
    var status: String
    let createdAt: TimeInterval
    var url: String?
}
