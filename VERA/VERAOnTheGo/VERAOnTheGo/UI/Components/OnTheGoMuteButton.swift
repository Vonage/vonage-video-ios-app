//
//  Created by Vonage on 17/10/26.
//

import SwiftUI
import VERACommonUI

/// The big microphone toggle that fills the centre of the On-the-Go screen.
///
/// Mic on: filled with the theme primary colour, white mic icon.
/// Mic off: neutral fill with an error-coloured border and mic-mute icon, so
/// the muted state does not rely on colour alone.
public struct OnTheGoMuteButton: View {

    @Environment(\.meetingRoomTheme) private var theme

    private let isMicEnabled: Bool
    private let action: () -> Void

    public init(isMicEnabled: Bool, action: @escaping () -> Void) {
        self.isMicEnabled = isMicEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                (isMicEnabled
                    ? VERACommonUIAsset.Images.microphone2Solid.swiftUIImage
                    : VERACommonUIAsset.Images.micMuteSolid.swiftUIImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 72)
                    .foregroundStyle(isMicEnabled ? theme.onPrimary : theme.error)
                Text(isMicEnabled ? "MICROPHONE ON".localized : "MICROPHONE OFF".localized)
                    .font(.subheadline.weight(.semibold))
                    .tracking(2)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(isMicEnabled ? theme.onPrimary : theme.error)
                Text(isMicEnabled ? "Tap to mute".localized : "Tap to unmute".localized)
                    .font(.title3.weight(.semibold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(isMicEnabled ? theme.onPrimary : theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isMicEnabled ? theme.primary : theme.vGray4)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(theme.error, lineWidth: isMicEnabled ? 0 : 3)
        )
        .accessibilityIdentifier(OnTheGoAccessibilityID.muteButton)
        .accessibilityLabel(
            isMicEnabled
                ? "Microphone, on. Double-tap to mute.".localized
                : "Microphone, off. Double-tap to unmute.".localized
        )
    }
}
