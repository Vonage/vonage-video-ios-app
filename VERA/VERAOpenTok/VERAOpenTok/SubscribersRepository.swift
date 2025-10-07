//
//  Created by Vonage on 12/9/25.
//

import Foundation

final actor SubscribersRepository {

    var all: [OpenTokSubscriber] {
        Array(subscriberStreams.values)
    }

    private var subscriberStreams: [String: OpenTokSubscriber] = [:]

    func addSubscriber(_ subscriber: OpenTokSubscriber) async {
        subscriberStreams[subscriber.id] = subscriber
    }

    func getSubscriber(id: String) async -> OpenTokSubscriber? {
        subscriberStreams[id]
    }

    func removeSubscriber(id: String) async {
        subscriberStreams.removeValue(forKey: id)
    }

    func reset() {
        subscriberStreams.removeAll()
    }
}
