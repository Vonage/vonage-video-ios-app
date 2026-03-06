//
//  Created by Vonage on 22/2/26.
//

import SwiftUI

/// About section showing app version and SDK information.
struct AboutSectionView: View {

    var body: some View {
        Form {
            Section("Application".localized) {
                infoRow(label: "App Version".localized, value: appVersion)
                infoRow(label: "Build".localized, value: buildNumber)
            }

            Section("SDK".localized) {
                infoRow(label: "Vonage Video SDK".localized, value: "2.32.1")
            }
        }
        .navigationTitle("About".localized)
    }

    // MARK: - Rows

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
    }

    // MARK: - Bundle Info

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationStack {
        AboutSectionView()
    }
    .preferredColorScheme(.dark)
}
#endif
