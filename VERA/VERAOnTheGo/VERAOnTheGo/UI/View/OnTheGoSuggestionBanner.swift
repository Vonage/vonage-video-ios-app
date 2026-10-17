//
//  Created by Vonage on 17/10/26.
//

import SwiftUI
import VERACommonUI

/// Non-blocking toast suggesting a switch to On-the-Go mode.
///
/// Presented at the top of the normal call screen. A thin progress bar drains
/// over ``OnTheGoConfiguration/suggestionTimeout``; when it empties the view
/// model treats it as "Not now".
public struct OnTheGoSuggestionBanner: View {

    @Environment(\.meetingRoomTheme) private var theme

    @Bindable private var viewModel: OnTheGoViewModel
    @State private var progress: CGFloat = 1

    public init(viewModel: OnTheGoViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "figure.walk")
                    .font(.title2)
                    .foregroundStyle(theme.textSecondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Looks like you're on the move.".localized)
                        .font(.footnote.weight(.semibold))
                    Text("Switch to On-the-Go mode? Camera and incoming video turn off.".localized)
                        .font(.footnote)
                }
                .foregroundStyle(theme.textSecondary)

                VStack(spacing: 6) {
                    Button("Switch".localized, action: viewModel.acceptSuggestion)
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.primary, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(theme.onPrimary)
                        .accessibilityIdentifier(OnTheGoAccessibilityID.suggestionSwitchButton)

                    Button("Not now".localized, action: viewModel.declineSuggestion)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                        .accessibilityIdentifier(OnTheGoAccessibilityID.suggestionNotNowButton)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            GeometryReader { geometry in
                Capsule()
                    .fill(theme.primary)
                    .frame(width: geometry.size.width * progress, height: 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 2)
            .padding(.horizontal, 14)
        }
        .background(theme.surface.opacity(0.96), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12).strokeBorder(theme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(OnTheGoAccessibilityID.suggestionBanner)
        .onAppear {
            withAnimation(.linear(duration: viewModel.configuration.suggestionTimeout)) {
                progress = 0
            }
        }
    }
}

#if DEBUG
    #Preview {
        OnTheGoSuggestionBanner(viewModel: .preview())
            .padding()
            .background(Color.black)
    }
#endif
