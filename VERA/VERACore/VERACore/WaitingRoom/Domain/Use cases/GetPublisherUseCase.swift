//
//  Created by Vonage on 15/7/25.
//

import Foundation

final class GetPublisherUseCase {

    private let publisherRepository: VERAPublisherRepository

    init(publisherRepository: VERAPublisherRepository) {
        self.publisherRepository = publisherRepository
    }

    public func invoke() -> VERAPublisher {
        publisherRepository.getPublisher()
    }
}
