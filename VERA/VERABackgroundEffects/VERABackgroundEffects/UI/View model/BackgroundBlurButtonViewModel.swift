//
//  Created by Vonage on 26/1/26.
//

import Foundation
import VERADomain

public final class BackgroundBlurButtonViewModel: ObservableObject {

    private let getCurrentPublisher: () throws -> VERAPublisher
    private let getProvider: () -> BackgroundEffectProvider
    private let getAppleVisionQuality: () -> AppleVisionSegmentationQuality

    @Published public var currentBlurLevel: BlurLevel = .none

    /// Creates a blur toggle view model.
    ///
    /// - Parameters:
    ///   - getCurrentPublisher: Resolves the current `VERAPublisher`.
    ///   - getProvider: Resolves the current background-effect provider preference.
    ///     Defaults to a closure returning `.vonage` so existing tests and call sites
    ///     that haven't migrated continue to behave identically.
    ///   - getAppleVisionQuality: Resolves the current Apple Vision quality preference.
    ///     Defaults to a closure returning `.fast`.
    public init(
        getCurrentPublisher: @escaping () throws -> VERAPublisher,
        getProvider: @escaping () -> BackgroundEffectProvider = { .vonage },
        getAppleVisionQuality: @escaping () -> AppleVisionSegmentationQuality = { .fast }
    ) {
        self.getCurrentPublisher = getCurrentPublisher
        self.getProvider = getProvider
        self.getAppleVisionQuality = getAppleVisionQuality
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
            try publisher.setBackgroundBlur(
                blurLevel: currentBlurLevel,
                provider: getProvider(),
                appleVisionQuality: getAppleVisionQuality()
            )
        } catch {

        }
    }
}
