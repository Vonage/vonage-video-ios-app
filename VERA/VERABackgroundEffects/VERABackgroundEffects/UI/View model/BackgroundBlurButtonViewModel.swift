//
//  Created by Vonage on 26/1/26.
//

import Foundation
import VERADomain

public final class BackgroundBlurButtonViewModel: ObservableObject {

    private let getCurrentPublisher: () throws -> VERAPublisher
    @Published public var currentVideoEffect: VideoEffect = .none

    public init(getCurrentPublisher: @escaping () throws -> VERAPublisher) {
        self.getCurrentPublisher = getCurrentPublisher
    }

    public func onTap() {
        let nextEffect: VideoEffect
        switch currentVideoEffect {
        case .none: nextEffect = .blurLow
        case .blurLow: nextEffect = .blurHigh
        case .blurHigh: nextEffect = .none
        case .backgroundImage: nextEffect = .none
        }

        apply(nextEffect)
    }

    public func apply(_ effect: VideoEffect) {
        currentVideoEffect = effect
        do {
            let publisher = try getCurrentPublisher()
            try publisher.applyVideoEffect(currentVideoEffect)
        } catch {

        }
    }
}
