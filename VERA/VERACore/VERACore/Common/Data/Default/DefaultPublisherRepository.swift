//
//  Created by Vonage on 2/12/25.
//

import Foundation

public final class DefaultPublisherRepository: PublisherRepository {

    private let publisherFactory: PublisherFactory
    private var publisher: VERAPublisher?

    public init(publisherFactory: PublisherFactory) {
        self.publisherFactory = publisherFactory
    }

    public func getPublisher() throws -> VERAPublisher {
        if let publisher = publisher {
            return publisher
        }

        let newPublisher = try publisherFactory.make(.init())
        self.publisher = newPublisher
        return newPublisher
    }

    public func resetPublisher() {
        publisher?.cleanUp()
        publisher = nil
    }

    public func recreatePublisher(_ settings: PublisherSettings) throws {
        publisher?.cleanUp()
        publisher = try publisherFactory.make(settings)
    }
}
