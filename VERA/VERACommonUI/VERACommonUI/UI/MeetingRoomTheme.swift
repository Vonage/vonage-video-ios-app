//
//  Created by Vonage on 23/4/26.
//

import SwiftUI

/// A complete set of colors for theming the meeting room experience.
///
/// Use ``vonage`` as a starting point and modify individual properties
/// to match your brand:
///
/// ```swift
/// var theme = MeetingRoomTheme.vonage
/// theme.primary = .blue
/// theme.surface = Color(.systemGray6)
/// ```
public struct MeetingRoomTheme: Sendable {

    // MARK: - Semantic Colors

    public var primary: Color
    public var primaryHover: Color
    public var secondary: Color
    public var tertiary: Color
    public var surface: Color
    public var background: Color
    public var accent: Color
    public var border: Color
    public var error: Color
    public var errorHover: Color
    public var success: Color
    public var successHover: Color
    public var warning: Color
    public var warningHover: Color
    public var disabled: Color

    // MARK: - On-* Colors

    public var onPrimary: Color
    public var onSecondary: Color
    public var onTertiary: Color
    public var onSurface: Color
    public var onBackground: Color
    public var onAccent: Color
    public var onError: Color
    public var onSuccess: Color
    public var onWarning: Color

    // MARK: - Text Colors

    public var textPrimary: Color
    public var textSecondary: Color
    public var textTertiary: Color
    public var textDisabled: Color

    // MARK: - Legacy Colors

    public var videoBackground: Color
    public var vGray0: Color
    public var vGray1: Color
    public var vGray2: Color
    public var vGray3: Color
    public var vGray4: Color

    /// The default Vonage theme, reading from the asset catalog.
    public static var vonage: MeetingRoomTheme {
        MeetingRoomTheme(
            primary: VERACommonUIAsset.SemanticColors.primary.swiftUIColor,
            primaryHover: VERACommonUIAsset.SemanticColors.primaryHover.swiftUIColor,
            secondary: VERACommonUIAsset.SemanticColors.secondary.swiftUIColor,
            tertiary: VERACommonUIAsset.SemanticColors.tertiary.swiftUIColor,
            surface: VERACommonUIAsset.SemanticColors.surface.swiftUIColor,
            background: VERACommonUIAsset.SemanticColors.background.swiftUIColor,
            accent: VERACommonUIAsset.SemanticColors.accent.swiftUIColor,
            border: VERACommonUIAsset.SemanticColors.border.swiftUIColor,
            error: VERACommonUIAsset.SemanticColors.error.swiftUIColor,
            errorHover: VERACommonUIAsset.SemanticColors.errorHover.swiftUIColor,
            success: VERACommonUIAsset.SemanticColors.success.swiftUIColor,
            successHover: VERACommonUIAsset.SemanticColors.successHover.swiftUIColor,
            warning: VERACommonUIAsset.SemanticColors.warning.swiftUIColor,
            warningHover: VERACommonUIAsset.SemanticColors.warningHover.swiftUIColor,
            disabled: VERACommonUIAsset.SemanticColors.disabled.swiftUIColor,
            onPrimary: VERACommonUIAsset.SemanticColors.onPrimary.swiftUIColor,
            onSecondary: VERACommonUIAsset.SemanticColors.onSecondary.swiftUIColor,
            onTertiary: VERACommonUIAsset.SemanticColors.onTertiary.swiftUIColor,
            onSurface: VERACommonUIAsset.SemanticColors.onSurface.swiftUIColor,
            onBackground: VERACommonUIAsset.SemanticColors.onBackground.swiftUIColor,
            onAccent: VERACommonUIAsset.SemanticColors.onAccent.swiftUIColor,
            onError: VERACommonUIAsset.SemanticColors.onError.swiftUIColor,
            onSuccess: VERACommonUIAsset.SemanticColors.onSuccess.swiftUIColor,
            onWarning: VERACommonUIAsset.SemanticColors.onWarning.swiftUIColor,
            textPrimary: VERACommonUIAsset.SemanticColors.textPrimary.swiftUIColor,
            textSecondary: VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor,
            textTertiary: VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor,
            textDisabled: VERACommonUIAsset.SemanticColors.textDisabled.swiftUIColor,
            videoBackground: VERACommonUIAsset.Colors.videoBackground.swiftUIColor,
            vGray0: VERACommonUIAsset.Colors.vGray0.swiftUIColor,
            vGray1: VERACommonUIAsset.Colors.vGray1.swiftUIColor,
            vGray2: VERACommonUIAsset.Colors.vGray2.swiftUIColor,
            vGray3: VERACommonUIAsset.Colors.vGray3.swiftUIColor,
            vGray4: VERACommonUIAsset.Colors.vGray4.swiftUIColor
        )
    }
}

// MARK: - Environment Key

private struct MeetingRoomThemeKey: EnvironmentKey {
    static let defaultValue = MeetingRoomTheme.vonage
}

extension EnvironmentValues {
    /// The meeting room theme injected by ``MeetingRoomBuilder``.
    public var meetingRoomTheme: MeetingRoomTheme {
        get { self[MeetingRoomThemeKey.self] }
        set { self[MeetingRoomThemeKey.self] = newValue }
    }
}
