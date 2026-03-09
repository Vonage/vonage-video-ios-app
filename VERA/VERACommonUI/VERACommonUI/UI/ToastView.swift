//
//  Created by Vonage on 22/12/25.
//

import SwiftUI
import VERADomain

public struct ToastView: View {
    public let item: ToastItem

    public init(item: ToastItem) {
        self.item = item
    }

    public var body: some View {
        HStack(spacing: 12) {
            item.image
                .font(.system(size: 20))

            Text(item.message)
                .foregroundColor(.black)
                .adaptiveFont(.bodyBase)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
