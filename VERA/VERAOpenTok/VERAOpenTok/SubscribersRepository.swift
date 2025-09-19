//
//  Created by Vonage on 12/9/25.
//

import Foundation

final actor SubscribersRepository {
    private var subscriberStreams: [String: OpenTokSubscriber] = [:]

    func addSubscriber(_ subscriber: OpenTokSubscriber) async {
        subscriberStreams[subscriber.id] = subscriber
        print("SubscribersRepository addSubscriber \(subscriber.id)")
    }

    func getSubscriber(id: String) async -> OpenTokSubscriber? {
        subscriberStreams[id]
    }

    func removeSubscriber(id: String) async {
        subscriberStreams.removeValue(forKey: id)
    }
}
