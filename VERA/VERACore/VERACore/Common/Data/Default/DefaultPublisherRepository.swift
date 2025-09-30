//
//  Created by Vonage on 16/7/25.
//

import Foundation

public final class DefaultPublisherRepository: PublisherRepository {

    private let publisherFactory: PublisherFactory
    private var publisher: VERAPublisher?

    public init(publisherFactory: PublisherFactory) {
        self.publisherFactory = publisherFactory
    }

    public func getPublisher() -> VERAPublisher {
        if let publisher = publisher {
            return publisher
        }
        self.publisher = publisherFactory.make(.init())
        return self.publisher!
    }

    public func resetPublisher() {
        publisher?.cleanUp()
        publisher = nil
    }

    public func recreatePublisher(_ settings: PublisherSettings) {
        publisher?.cleanUp()
        publisher = publisherFactory.make(settings)
    }
}
