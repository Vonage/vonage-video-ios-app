// swift-format-ignore-file
//
// TypographyStyle.swift
// Generated from theme.json - DO NOT EDIT MANUALLY
//
import SwiftUI

public struct TypographyConfig {
    public let fontSize: CGFloat
    public let lineHeight: CGFloat
    public let weight: Font.Weight
    public let lineSpacing: CGFloat

    public init(fontSize: CGFloat, lineHeight: CGFloat, weight: Font.Weight, lineSpacing: CGFloat) {
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.weight = weight
        self.lineSpacing = lineSpacing
    }
}

public enum TypographyStyle {
    case headline
    case subtitle
    case heading1
    case heading2
    case heading3
    case heading4
    case bodyExtended
    case bodyExtendedSemibold
    case bodyBase
    case bodyBaseSemibold
    case caption
    case captionSemibold

    public var mobileConfig: TypographyConfig {
        switch self {
        case .headline: return TypographyConfig(fontSize: 32, lineHeight: 40, weight: .medium, lineSpacing: 8.0)
        case .subtitle: return TypographyConfig(fontSize: 30, lineHeight: 40, weight: .medium, lineSpacing: 10.0)
        case .heading1: return TypographyConfig(fontSize: 28, lineHeight: 36, weight: .medium, lineSpacing: 8.0)
        case .heading2: return TypographyConfig(fontSize: 24, lineHeight: 32, weight: .medium, lineSpacing: 8.0)
        case .heading3: return TypographyConfig(fontSize: 20, lineHeight: 28, weight: .medium, lineSpacing: 8.0)
        case .heading4: return TypographyConfig(fontSize: 18, lineHeight: 24, weight: .medium, lineSpacing: 6.0)
        case .bodyExtended: return TypographyConfig(fontSize: 16, lineHeight: 24, weight: .regular, lineSpacing: 8.0)
        case .bodyExtendedSemibold: return TypographyConfig(fontSize: 16, lineHeight: 24, weight: .semibold, lineSpacing: 8.0)
        case .bodyBase: return TypographyConfig(fontSize: 14, lineHeight: 20, weight: .regular, lineSpacing: 6.0)
        case .bodyBaseSemibold: return TypographyConfig(fontSize: 14, lineHeight: 20, weight: .semibold, lineSpacing: 6.0)
        case .caption: return TypographyConfig(fontSize: 12, lineHeight: 16, weight: .regular, lineSpacing: 4.0)
        case .captionSemibold: return TypographyConfig(fontSize: 12, lineHeight: 16, weight: .semibold, lineSpacing: 4.0)
        }
    }

    public var desktopConfig: TypographyConfig {
        switch self {
        case .headline: return TypographyConfig(fontSize: 66, lineHeight: 88, weight: .medium, lineSpacing: 22.0)
        case .subtitle: return TypographyConfig(fontSize: 52, lineHeight: 68, weight: .medium, lineSpacing: 16.0)
        case .heading1: return TypographyConfig(fontSize: 40, lineHeight: 52, weight: .medium, lineSpacing: 12.0)
        case .heading2: return TypographyConfig(fontSize: 32, lineHeight: 44, weight: .medium, lineSpacing: 12.0)
        case .heading3: return TypographyConfig(fontSize: 26, lineHeight: 36, weight: .medium, lineSpacing: 10.0)
        case .heading4: return TypographyConfig(fontSize: 20, lineHeight: 28, weight: .medium, lineSpacing: 8.0)
        case .bodyExtended: return TypographyConfig(fontSize: 16, lineHeight: 24, weight: .regular, lineSpacing: 8.0)
        case .bodyExtendedSemibold: return TypographyConfig(fontSize: 16, lineHeight: 24, weight: .semibold, lineSpacing: 8.0)
        case .bodyBase: return TypographyConfig(fontSize: 14, lineHeight: 20, weight: .regular, lineSpacing: 6.0)
        case .bodyBaseSemibold: return TypographyConfig(fontSize: 14, lineHeight: 20, weight: .semibold, lineSpacing: 6.0)
        case .caption: return TypographyConfig(fontSize: 12, lineHeight: 16, weight: .regular, lineSpacing: 4.0)
        case .captionSemibold: return TypographyConfig(fontSize: 12, lineHeight: 16, weight: .semibold, lineSpacing: 4.0)
        }
    }
}

public extension View {
    func adaptiveFont(_ style: TypographyStyle) -> some View {
        self.modifier(AdaptiveFontModifier(style: style))
    }
}

private struct AdaptiveFontModifier: ViewModifier {
    let style: TypographyStyle
    @Environment(\.horizontalSizeClass) var sizeClass

    func body(content: Content) -> some View {
        let config = sizeClass == .compact ? style.mobileConfig : style.desktopConfig
        content
            .font(.system(size: config.fontSize, weight: config.weight))
            .lineSpacing(config.lineSpacing)
    }
}
