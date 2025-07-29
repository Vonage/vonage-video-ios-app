//
//  Created by Vonage on 29/7/25.
//

import Foundation
import VERAOpenTok
import OpenTok

class OpenTokPublisherSpy: OpenTokPublisher {
    init() {
        super.init(publisher: OTPublisher(delegate: nil)!)
    }
}
