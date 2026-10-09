//
//  Created by Vonage on 12/3/26.
//

import Foundation
import SwiftUI
import VERACommonUI
import VERADomain

extension NoiseSuppressionState {
    public var image: Image {
        switch self {
        case .enabled: VERACommonUIAsset.Images.noiseSuppressionEnabled.swiftUIImage
        case .idle, .disabled: VERACommonUIAsset.Images.noiseSuppressionDisabled.swiftUIImage
        }
    }

    public var label: String {
        switch self {
        case .enabled:
            String(
                localized: "Enabled", bundle: AppLanguageStore.shared.localizedBundle(in: .module),
                locale: AppLanguageStore.shared.locale)
        case .idle, .disabled:
            String(
                localized: "Disabled", bundle: AppLanguageStore.shared.localizedBundle(in: .module),
                locale: AppLanguageStore.shared.locale)
        }
    }
}
