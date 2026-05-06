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
        let newBlurLevel: BlurLevel
        switch currentBlurLevel {
        case .none: newBlurLevel = .low
        case .low: newBlurLevel = .high
        case .high: newBlurLevel = .none
        }

        update(blurLevel: newBlurLevel)
    }

    public func update(blurLevel: BlurLevel) {
        currentBlurLevel = blurLevel
        do {
            let publisher = try getCurrentPublisher()
            try publisher.setBackgroundBlur(blurLevel: currentBlurLevel)
        } catch {

        }
    }
}
