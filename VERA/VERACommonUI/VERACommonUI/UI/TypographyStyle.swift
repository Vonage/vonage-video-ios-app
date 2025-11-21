//
//  Created by Vonage on 13/11/25.
//

import SwiftUI

// MARK: - Typography Style

public enum TypographyStyle {
    case headline, subtitle
    case heading1, heading2, heading3, heading4
    case bodyExtended, bodyExtendedSemibold
    case bodyBase, bodyBaseSemibold
    case caption, captionSemibold
}

// MARK: - Typography Configuration

private struct TypographyConfig {
    let fontSize: CGFloat
    let lineHeight: CGFloat
    let weight: Font.Weight

    var lineSpacing: CGFloat {
        lineHeight - fontSize
    }
}

// MARK: - Adaptive Font Modifier

private struct AdaptiveFontModifier: ViewModifier {
    let style: TypographyStyle
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    func body(content: Content) -> some View {
        let isCompact = horizontalSizeClass == .compact || verticalSizeClass == .compact
        let config = configuration(for: style, isCompact: isCompact)
        content
            .font(.system(size: config.fontSize, weight: config.weight))
            .lineSpacing(config.lineSpacing)
    }

    private func configuration(for style: TypographyStyle, isCompact: Bool) -> TypographyConfig {

        switch style {
        case .headline:
            return isCompact
                ? TypographyConfig(fontSize: 32, lineHeight: 40, weight: .medium)
                : TypographyConfig(fontSize: 66, lineHeight: 88, weight: .medium)

        case .subtitle:
            return isCompact
                ? TypographyConfig(fontSize: 30, lineHeight: 40, weight: .medium)
                : TypographyConfig(fontSize: 52, lineHeight: 68, weight: .medium)

        case .heading1:
            return isCompact
                ? TypographyConfig(fontSize: 28, lineHeight: 36, weight: .medium)
                : TypographyConfig(fontSize: 40, lineHeight: 52, weight: .medium)

        case .heading2:
            return isCompact
                ? TypographyConfig(fontSize: 24, lineHeight: 32, weight: .medium)
                : TypographyConfig(fontSize: 32, lineHeight: 44, weight: .medium)

        case .heading3:
            return isCompact
                ? TypographyConfig(fontSize: 20, lineHeight: 28, weight: .medium)
                : TypographyConfig(fontSize: 26, lineHeight: 36, weight: .medium)

        case .heading4:
            return isCompact
                ? TypographyConfig(fontSize: 18, lineHeight: 24, weight: .medium)
                : TypographyConfig(fontSize: 20, lineHeight: 28, weight: .medium)

        case .bodyExtended:
            return TypographyConfig(fontSize: 16, lineHeight: 24, weight: .regular)

        case .bodyExtendedSemibold:
            return TypographyConfig(fontSize: 16, lineHeight: 24, weight: .semibold)

        case .bodyBase:
            return TypographyConfig(fontSize: 14, lineHeight: 20, weight: .regular)

        case .bodyBaseSemibold:
            return TypographyConfig(fontSize: 14, lineHeight: 20, weight: .semibold)

        case .caption:
            return TypographyConfig(fontSize: 12, lineHeight: 16, weight: .regular)

        case .captionSemibold:
            return TypographyConfig(fontSize: 12, lineHeight: 16, weight: .semibold)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies adaptive typography that automatically adjusts based on size class
    /// - Parameter style: The typography style to apply
    /// - Returns: A view with the appropriate font and line spacing for the current size class
    public func adaptiveFont(_ style: TypographyStyle) -> some View {
        modifier(AdaptiveFontModifier(style: style))
    }
}
