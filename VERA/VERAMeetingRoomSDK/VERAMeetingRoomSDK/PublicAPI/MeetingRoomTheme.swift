//
//  Created by Vonage on 28/5/26.
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

    /// Creates a meeting room theme with all color properties.
    public init(
        primary: Color,
        primaryHover: Color,
        secondary: Color,
        tertiary: Color,
        surface: Color,
        background: Color,
        accent: Color,
        border: Color,
        error: Color,
        errorHover: Color,
        success: Color,
        successHover: Color,
        warning: Color,
        warningHover: Color,
        disabled: Color,
        onPrimary: Color,
        onSecondary: Color,
        onTertiary: Color,
        onSurface: Color,
        onBackground: Color,
        onAccent: Color,
        onError: Color,
        onSuccess: Color,
        onWarning: Color,
        textPrimary: Color,
        textSecondary: Color,
        textTertiary: Color,
        textDisabled: Color,
        videoBackground: Color,
        vGray0: Color,
        vGray1: Color,
        vGray2: Color,
        vGray3: Color,
        vGray4: Color
    ) {
        self.primary = primary
        self.primaryHover = primaryHover
        self.secondary = secondary
        self.tertiary = tertiary
        self.surface = surface
        self.background = background
        self.accent = accent
        self.border = border
        self.error = error
        self.errorHover = errorHover
        self.success = success
        self.successHover = successHover
        self.warning = warning
        self.warningHover = warningHover
        self.disabled = disabled
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
        self.onTertiary = onTertiary
        self.onSurface = onSurface
        self.onBackground = onBackground
        self.onAccent = onAccent
        self.onError = onError
        self.onSuccess = onSuccess
        self.onWarning = onWarning
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textTertiary = textTertiary
        self.textDisabled = textDisabled
        self.videoBackground = videoBackground
        self.vGray0 = vGray0
        self.vGray1 = vGray1
        self.vGray2 = vGray2
        self.vGray3 = vGray3
        self.vGray4 = vGray4
    }

    /// The default Vonage theme with hardcoded color values.
    public static var vonage: MeetingRoomTheme {
        MeetingRoomTheme(
            primary: Color(red: 0.47, green: 0.09, blue: 0.96),
            primaryHover: Color(red: 0.36, green: 0.04, blue: 0.78),
            secondary: Color(red: 0.16, green: 0.16, blue: 0.16),
            tertiary: Color(red: 0.24, green: 0.24, blue: 0.24),
            surface: Color(red: 0.12, green: 0.12, blue: 0.12),
            background: Color(red: 0.07, green: 0.07, blue: 0.07),
            accent: Color(red: 0.47, green: 0.09, blue: 0.96),
            border: Color(red: 0.30, green: 0.30, blue: 0.30),
            error: Color(red: 0.90, green: 0.22, blue: 0.21),
            errorHover: Color(red: 0.74, green: 0.16, blue: 0.16),
            success: Color(red: 0.20, green: 0.78, blue: 0.35),
            successHover: Color(red: 0.15, green: 0.63, blue: 0.28),
            warning: Color(red: 1.00, green: 0.76, blue: 0.03),
            warningHover: Color(red: 0.85, green: 0.65, blue: 0.01),
            disabled: Color(red: 0.40, green: 0.40, blue: 0.40),
            onPrimary: Color.white,
            onSecondary: Color.white,
            onTertiary: Color.white,
            onSurface: Color.white,
            onBackground: Color.white,
            onAccent: Color.white,
            onError: Color.white,
            onSuccess: Color.white,
            onWarning: Color.black,
            textPrimary: Color.white,
            textSecondary: Color(red: 0.70, green: 0.70, blue: 0.70),
            textTertiary: Color(red: 0.50, green: 0.50, blue: 0.50),
            textDisabled: Color(red: 0.40, green: 0.40, blue: 0.40),
            videoBackground: Color(red: 0.07, green: 0.07, blue: 0.07),
            vGray0: Color(red: 0.12, green: 0.12, blue: 0.12),
            vGray1: Color(red: 0.16, green: 0.16, blue: 0.16),
            vGray2: Color(red: 0.24, green: 0.24, blue: 0.24),
            vGray3: Color(red: 0.40, green: 0.40, blue: 0.40),
            vGray4: Color(red: 0.60, green: 0.60, blue: 0.60)
        )
    }
}

// MARK: - Internal Conversion

import VERACommonUI

extension VERAMeetingRoomSDK.MeetingRoomTheme {
    func toInternal() -> VERACommonUI.MeetingRoomTheme {
        VERACommonUI.MeetingRoomTheme(
            primary: primary,
            primaryHover: primaryHover,
            secondary: secondary,
            tertiary: tertiary,
            surface: surface,
            background: background,
            accent: accent,
            border: border,
            error: error,
            errorHover: errorHover,
            success: success,
            successHover: successHover,
            warning: warning,
            warningHover: warningHover,
            disabled: disabled,
            onPrimary: onPrimary,
            onSecondary: onSecondary,
            onTertiary: onTertiary,
            onSurface: onSurface,
            onBackground: onBackground,
            onAccent: onAccent,
            onError: onError,
            onSuccess: onSuccess,
            onWarning: onWarning,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textTertiary: textTertiary,
            textDisabled: textDisabled,
            videoBackground: videoBackground,
            vGray0: vGray0,
            vGray1: vGray1,
            vGray2: vGray2,
            vGray3: vGray3,
            vGray4: vGray4
        )
    }
}
