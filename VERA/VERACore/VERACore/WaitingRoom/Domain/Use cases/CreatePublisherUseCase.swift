//
//  Created by Vonage on 15/7/25.
//

import Foundation

final class CreatePublisherUseCase {

    private let publisherFactory: PublisherFactory

    init(publisherFactory: PublisherFactory) {
        self.publisherFactory = publisherFactory
    }

    public func invoke() throws -> VERAPublisher {
        return try publisherFactory.make()
    }
}
