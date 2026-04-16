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
    public let item: ToastItem

    public init(item: ToastItem) {
        self.item = item
    }

    public var body: some View {
        HStack(spacing: ToastViewConstants.contentSpacing) {
            item.image
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
    var image: some View {
        switch mode {
        case .info:
            VERACommonUIAsset.Images.infoLine.swiftUIImage
                .foregroundStyle(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
        case .failure:
            VERACommonUIAsset.Images.errorLine.swiftUIImage
                .foregroundStyle(VERACommonUIAsset.SemanticColors.error.swiftUIColor)
        case .warning:
            VERACommonUIAsset.Images.warningLine.swiftUIImage
                .foregroundStyle(VERACommonUIAsset.SemanticColors.error.swiftUIColor)
        case .success:
            VERACommonUIAsset.Images.checkCircleLine.swiftUIImage
                .foregroundStyle(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
        }
    }
}

struct GlassBackground: View {
    var body: some View {
        #if os(macOS)
            RoundedRectangle(cornerRadius: BorderRadius.large.value)
                .fill(VERACommonUIAsset.SemanticColors.tertiary.swiftUIColor)
        #else
            Group {
                if #available(iOS 26.0, *) {
                    glassEffectBackground()
                } else {
                    RoundedRectangle(cornerRadius: BorderRadius.large.value)
                        .fill(VERACommonUIAsset.SemanticColors.tertiary.swiftUIColor)
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
