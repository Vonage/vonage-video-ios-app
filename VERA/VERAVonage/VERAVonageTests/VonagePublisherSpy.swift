//
//  Created by Vonage on 29/7/25.
//

import Foundation
import OpenTok
import VERATestHelpers
import VERAVonage

class VonagePublisherSpy: VonagePublisher {
    init() {
        super.init(
            publisher: OTPublisher(delegate: nil)!,
            transformerFactory: MockTransformerFactory())
    }
}
