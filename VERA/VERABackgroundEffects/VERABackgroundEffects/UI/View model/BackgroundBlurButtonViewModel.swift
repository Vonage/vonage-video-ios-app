//
//  Created by Vonage on 26/1/26.
//

import Foundation
import VERADomain

public final class BackgroundBlurButtonViewModel: ObservableObject {

    private let publisherRepository: PublisherRepository
    @Published public var currentBlurLevel: BlurLevel = .none

    public init(publisherRepository: PublisherRepository) {
        self.publisherRepository = publisherRepository
    }

    public func onTap() {
        switch currentBlurLevel {
        case .none: currentBlurLevel = .low
        case .low: currentBlurLevel = .high
        case .high: currentBlurLevel = .none
        }

        do {
            let publisher = try publisherRepository.getPublisher()
            try publisher.setBackgroundBlur(blurLevel: currentBlurLevel)
        } catch {

        }
    }
}
