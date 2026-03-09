//
//  Created by Vonage on 26/1/26.
//

import Foundation
import VERADomain

public final class BackgroundBlurButtonViewModel: ObservableObject {

    private let getCurrentPublisher: () throws -> VERAPublisher
    @Published public var currentBlurLevel: BlurLevel = .none

    public init(getCurrentPublisher: @escaping () throws -> VERAPublisher) {
        self.getCurrentPublisher = getCurrentPublisher
    }

    public func onTap() {
        switch currentBlurLevel {
        case .none: currentBlurLevel = .low
        case .low: currentBlurLevel = .high
        case .high: currentBlurLevel = .none
        }

        do {
            let publisher = try getCurrentPublisher()
            try publisher.setBackgroundBlur(blurLevel: currentBlurLevel)
        } catch {

        }
    }
}
