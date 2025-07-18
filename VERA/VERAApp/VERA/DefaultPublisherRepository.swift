//
//  Created by Vonage on 16/7/25.
//

import Foundation
import VERACore

public final class DefaultPublisherRepository: PublisherRepository {

    private let publisherFactory: PublisherFactory
    private var publisher: VERACore.VERAPublisher?

    public init(publisherFactory: PublisherFactory) {
        self.publisherFactory = publisherFactory
    }

    public func getPublisher() -> VERACore.VERAPublisher {
        if let publisher = publisher {
            return publisher
        }
        self.publisher = publisherFactory.make(.init())
        return self.publisher!
    }

    public func resetPublisher() {
        publisher = nil
    }

    public func recreatePublisher(_ settings: PublisherSettings) {
        publisher = publisherFactory.make(settings)
    }
}
