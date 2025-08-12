//
//  Created by Vonage on 8/8/25.
//

import Foundation

public final class DefaultCameraPreviewProviderRepository: CameraPreviewProviderRepository {

    private let publisherFactory: PublisherFactory
    private var publisher: VERAPublisher?

    public init(publisherFactory: PublisherFactory) {
        self.publisherFactory = publisherFactory
    }

    public func getPublisher() async -> VERAPublisher {
        if let publisher = publisher {
            return publisher
        }
        self.publisher = await publisherFactory.make(.init(scaleBehavior: .fit))
        return self.publisher!
    }

    public func resetPublisher() {
        publisher = nil
    }
}
