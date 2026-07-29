//
//  SettingsAccessibilityID.swift
//  VERASettings
//
//  Created by Vonage
//

import Foundation

/// Centralized accessibility identifiers for the Settings module.
///
/// These identifiers are used by Maestro E2E tests to locate and verify UI elements.
/// Context-dependent controls use `-picker`/`-toggle` suffix when editable
/// and `-locked` suffix when in read-only state.
enum SettingsAccessibilityID {
    // MARK: - Screen

    static let screen = "settings-screen"

    // MARK: - Video Section - Always Editable

    static let videoBitratePicker = "settings-video-bitrate-picker"
    static let videoDegradationPicker = "settings-video-degradation-picker"

    // MARK: - Video Section - Context-Dependent

    static let codecModePicker = "settings-codec-mode-picker"
    static let codecModeLocked = "settings-codec-mode-locked"
    static let frameRatePicker = "settings-frame-rate-picker"
    static let frameRateLocked = "settings-frame-rate-locked"
    static let resolutionPicker = "settings-resolution-picker"
    static let resolutionLocked = "settings-resolution-locked"

    // MARK: - Audio Section - Context-Dependent

    static let audioBitratePicker = "settings-audio-bitrate-picker"
    static let audioBitrateLocked = "settings-audio-bitrate-locked"
    static let opusDtxToggle = "settings-opus-dtx-toggle"
    static let opusDtxLocked = "settings-opus-dtx-locked"
    static let publisherFallbackToggle = "settings-publisher-fallback-toggle"
    static let publisherFallbackLocked = "settings-publisher-fallback-locked"
    static let subscriberFallbackToggle = "settings-subscriber-fallback-toggle"
    static let subscriberFallbackLocked = "settings-subscriber-fallback-locked"

    // MARK: - General Section

    static let overlayStatsToggle = "settings-overlay-stats-toggle"
    static let resetDefaultsButton = "settings-reset-defaults-button"
    static let waitingRoomSettingsButton = "waiting-room-settings-button"
}
