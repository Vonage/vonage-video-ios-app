//
//  Created by Vonage on 18/6/26.
//

import SwiftUI
import VERACommonUI
import VERADomain

extension ArchivingState {
    public var bottomBarLabel: String {
        isArchiving
            ? String(
                localized: "Stop Recording", bundle: AppLanguageStore.shared.localizedBundle(in: .veraArchiving),
                locale: AppLanguageStore.shared.locale)
            : String(
                localized: "Start Recording", bundle: AppLanguageStore.shared.localizedBundle(in: .veraArchiving),
                locale: AppLanguageStore.shared.locale)
    }

    public var bottomBarAccessibilityIdentifier: String {
        isArchiving
            ? ArchivingAccessibilityID.stopRecordingButton
            : ArchivingAccessibilityID.startRecordingButton
    }

    public var bottomBarImage: Image {
        isArchiving
            ? VERACommonUIAsset.Images.radioChecked2Line.swiftUIImage
            : VERACommonUIAsset.Images.radioChecked2Solid.swiftUIImage
    }
}
