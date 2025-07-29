//
//  Created by Vonage on 29/7/25.
//

import Foundation
import OpenTok
import VERAOpenTok

class OpenTokPublisherSpy: OpenTokPublisher {
    init() {
        super.init(publisher: OTPublisher(delegate: nil)!)
    }
}
