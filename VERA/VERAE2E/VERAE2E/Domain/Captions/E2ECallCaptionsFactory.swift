//
//  Created by Vonage on 8/6/26.
//

import VERADomain

enum E2ECallCaptionsFactory {
    static func enabledCaptions() -> [CaptionItem] {
        [
            CaptionItem(
                speakerName: "Test User",
                text: "E2E captions are enabled",
                isMe: true
            )
        ]
    }
}
