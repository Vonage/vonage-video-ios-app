//
//  Created by Vonage on 8/8/25.
//

import Foundation

struct VideoDimensions {
    // Zero dimensions trigger the 16:9 fallback in Participant.aspectRatio, so the
    // publisher tile fills its 16:9 card from the start instead of appearing as a
    // smaller 4:3 box with gray letterbox bars while the stream is establishing.
    static let initial = CGSize(width: 0, height: 0)
}
