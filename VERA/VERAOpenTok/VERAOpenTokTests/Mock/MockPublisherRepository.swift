//
//  Created by Vonage on 30/7/25.
//

import Foundation
import OpenTok
import VERACore
import VERAOpenTok

class MockPublisherRepository: PublisherRepository {

    @MainActor
    func getPublisher() async -> any VERACore.VERAPublisher {
        OpenTokPublisher(publisher: OTPublisher(delegate: nil)!)
    }

    func resetPublisher() {
    }

    func recreatePublisher(_ settings: VERACore.PublisherSettings) async {
    }
}
