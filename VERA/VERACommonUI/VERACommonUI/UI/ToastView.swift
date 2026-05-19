//
//  Created by Vonage on 22/12/25.
//

import SwiftUI
import VERADomain

/// Layout constants for the toast notification view.
private enum ToastViewConstants {
    /// Spacing between icon and message text.
    static let contentSpacing: CGFloat = 12
    /// Font size of the leading icon.
    static let iconSize: CGFloat = 20
    /// Horizontal padding around toast content.
    static let horizontalPadding: CGFloat = 16
    /// Vertical padding around toast content.
    static let verticalPadding: CGFloat = 12
}

public struct ToastView: View {
    @Environment(\.meetingRoomTheme) private var theme
    public let item: ToastItem

    public init(item: ToastItem) {
        self.item = item
    }

    public var body: some View {
        HStack(spacing: ToastViewConstants.contentSpacing) {
            item.image(theme: theme)
                .font(.system(size: ToastViewConstants.iconSize))

            Text(item.message)
                .foregroundColor(.black)
                .adaptiveFont(.bodyBase)
                .lineLimit(2)
        }
        .padding(.horizontal, ToastViewConstants.horizontalPadding)
        .padding(.vertical, ToastViewConstants.verticalPadding)
        .background(
            GlassBackground()
        )
    }
}
extension ToastItem {
    func image(theme: MeetingRoomTheme) -> some View {
        switch mode {
        case .info:
            VERACommonUIAsset.Images.infoLine.swiftUIImage
                .foregroundStyle(theme.primary)
        case .failure:
            VERACommonUIAsset.Images.errorLine.swiftUIImage
                .foregroundStyle(theme.error)
        case .warning:
            VERACommonUIAsset.Images.warningLine.swiftUIImage
                .foregroundStyle(theme.error)
        case .success:
            VERACommonUIAsset.Images.checkCircleLine.swiftUIImage
                .foregroundStyle(theme.primary)
        }
    }
}

struct GlassBackground: View {
    @Environment(\.meetingRoomTheme) private var theme

    var body: some View {
        #if os(macOS)
            RoundedRectangle(cornerRadius: BorderRadius.large.value)
                .fill(theme.tertiary)
        #else
            Group {
                if #available(iOS 26.0, *) {
                    glassEffectBackground()
                } else {
                    RoundedRectangle(cornerRadius: BorderRadius.large.value)
                        .fill(theme.tertiary)
                }
            }
        #endif
    }

    #if !os(macOS)
        @available(iOS 26.0, *)
        private func glassEffectBackground() -> some View {
            RoundedRectangle(cornerRadius: BorderRadius.large.value)
                .glassEffect(in: .rect(cornerRadius: BorderRadius.large.value))
        }
    #endif
}

#Preview {
    ToastView(item: .init(message: "An error occurred", mode: .warning))
        .padding()
}
