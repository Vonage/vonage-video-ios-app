//
//  Created by Vonage on 12/9/25.
//

import Foundation

final actor SubscribersRepository {

    var all: [VonageSubscriber] {
        Array(subscriberStreams.values)
    }

    private var subscriberStreams: [String: VonageSubscriber] = [:]

    func addSubscriber(_ subscriber: VonageSubscriber) async {
        subscriberStreams[subscriber.id] = subscriber
    }

    func getSubscriber(id: String) async -> VonageSubscriber? {
        subscriberStreams[id]
    }

    func removeSubscriber(id: String) async {
        subscriberStreams.removeValue(forKey: id)
    }

    func reset() {
        subscriberStreams.removeAll()
    }
}
