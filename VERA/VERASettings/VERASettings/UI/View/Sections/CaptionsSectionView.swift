//
//  Created by Vonage on 21/10/26.
//

import SwiftUI
import VERACommonUI

/// Captions section content: the per-user captions translation language.
///
/// The choice applies immediately, also during an active call, so it has no active-call lock.
/// Returns `Section` blocks intended to be embedded inside a parent `Form`.
struct CaptionsSectionView: View {
    @Bindable var viewModel: SettingsViewModel
    private let isCompactLayout: Bool

    init(viewModel: SettingsViewModel, isCompactLayout: Bool = false) {
        self.viewModel = viewModel
        self.isCompactLayout = isCompactLayout
    }

    var body: some View {
        if isCompactLayout {
            VStack(alignment: .leading, spacing: 8) {
                languagePicker
                descriptionText
            }
        } else {
            Section {
                languagePicker
            } header: {
                Text("Captions language".localized)
            } footer: {
                descriptionText
            }
        }
    }

    private var languagePicker: some View {
        Picker("Captions language".localized, selection: $viewModel.settingsPreference.captionsTranslationLanguage) {
            Text("Original (no translation)".localized).tag(String?.none)
            ForEach(CaptionsTranslationLanguage.currentLocaleOptions, id: \.code) { option in
                Text(option.name).tag(String?.some(option.code))
            }
        }
        .accessibilityIdentifier(SettingsAccessibilityID.captionsLanguagePicker)
    }

    private var descriptionText: some View {
        Text(
            "Translates other participants' captions into the selected language. Your own captions stay in the original language."
                .localized
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Previews

#if DEBUG
    #Preview {
        Form {
            CaptionsSectionView(viewModel: .preview, isCompactLayout: true)
        }
        .preferredColorScheme(.dark)
    }
#endif
