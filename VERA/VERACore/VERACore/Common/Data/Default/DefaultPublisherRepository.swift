//
//  Created by Vonage on 16/7/25.
//

import Foundation

public final class DefaultPublisherRepository: PublisherRepository {

    public enum Error: Swift.Error {
        case noPublisher
    }

    private let publisherFactory: PublisherFactory
    private var publisher: VERAPublisher?

    public init(publisherFactory: PublisherFactory) {
        self.publisherFactory = publisherFactory
    }

    public func getPublisher() throws -> VERAPublisher {
        if let publisher = publisher {
            return publisher
        }
        self.publisher = try publisherFactory.make(.init())
        if let selfPublisher = self.publisher {
            return selfPublisher
        } else {
            throw Error.noPublisher
        }
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
