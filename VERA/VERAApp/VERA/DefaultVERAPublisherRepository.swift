//
//  Created by Vonage on 16/7/25.
//

import Foundation
import VERACore

final class DefaultVERAPublisherRepository: PublisherRepository {

    private let publisherFactory: PublisherFactory
    private var publisher: VERACore.VERAPublisher?

    public init(publisherFactory: PublisherFactory) {
        self.publisherFactory = publisherFactory
    }

    func getPublisher() -> VERACore.VERAPublisher {
        if let publisher = publisher {
            return publisher
        }
        self.publisher = publisherFactory.make()
        return self.publisher!
    }
    
    func resetPublisher() {
        publisher = nil
    }
}
