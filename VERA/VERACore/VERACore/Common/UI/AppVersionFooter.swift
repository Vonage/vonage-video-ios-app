//
//  Created by Vonage on 8/10/26.
//

import SwiftUI
import VERACommonUI

struct AppVersionDisplay {
    let appVersion: String?
    let sdkVersion: String?

    static func versionText(appVersion: String?, sdkVersion: String?) -> String {
        "v\(appVersion ?? "Unknown") (SDK \(sdkVersion ?? "Unknown"))"
    }
}

private struct AppVersionDisplayKey: EnvironmentKey {
    static let defaultValue: AppVersionDisplay? = nil
}

extension EnvironmentValues {
    var appVersionDisplay: AppVersionDisplay? {
        get { self[AppVersionDisplayKey.self] }
        set { self[AppVersionDisplayKey.self] = newValue }
    }
}

struct AppVersionFooter: View {
    @Environment(\.appVersionDisplay) private var versionDisplay
    private let appVersion: String?
    private let sdkVersion: String?

    init(
        appVersion: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
        sdkVersion: String? = Bundle.main.object(forInfoDictionaryKey: "VonageVideoSDKVersion") as? String
    ) {
        self.appVersion = appVersion
        self.sdkVersion = sdkVersion
    }

    var body: some View {
        HStack(spacing: 8) {
            GHRepoButton()

            VStack(alignment: .leading, spacing: 2) {
                Text("Vonage Video Reference Application", bundle: .veraCore)
                    .adaptiveFont(.bodyBase)
                    .foregroundColor(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)

                Text(
                    AppVersionDisplay.versionText(
                        appVersion: versionDisplay?.appVersion ?? appVersion,
                        sdkVersion: versionDisplay?.sdkVersion ?? sdkVersion
                    )
                )
                .accessibilityIdentifier(LandingPageAccessibilityID.versionFooter)
                .adaptiveFont(.caption)
                .foregroundColor(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
            }
        }
    }
}

#Preview {
    AppVersionFooter(appVersion: "1.3", sdkVersion: "2.35.1")
}
