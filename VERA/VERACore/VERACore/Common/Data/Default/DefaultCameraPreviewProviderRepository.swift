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

    public func getPublisher() -> VERAPublisher {
        if let publisher = publisher {
            return publisher
        }
        let producedPublisher = publisherFactory.make(.init(scaleBehavior: .fit))
        self.publisher = producedPublisher
        return producedPublisher
    }

    public func resetPublisher() {
        publisher = nil
    }
}
