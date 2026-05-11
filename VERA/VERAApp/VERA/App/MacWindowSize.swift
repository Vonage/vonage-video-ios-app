//
//  Created by Vonage on 11/5/26.
//

import Foundation
import SwiftUI
import UIKit
import os.log

/// Sets the initial window size on macOS ("Designed for iPad on Mac").
///
/// The Vera waiting room and meeting room are laid out for a wide window on Mac
/// — splitting the screen 50/50 between preview and the join form, with a
/// performance HUD overlay. The system's default iPad-on-Mac window size is too
/// small for that to feel right. We bump the initial size once per scene.
///
/// `UIWindowScene.GeometryPreferences.Mac` only exposes the initial system
/// frame; no minimum/maximum is enforced here, so the user can freely resize
/// the window afterwards.
///
/// No-op on iPhone/iPad.
struct MacWindowSizeModifier: ViewModifier {

    /// Persistent-identifier set of scenes we've already sized. SwiftUI's
    /// `.onAppear` fires every time the modified view re-enters the hierarchy
    /// (e.g. when the user navigates back to the landing page); without this
    /// guard we'd re-apply 1440×900 on every nav, overriding any manual resize.
    private static var sizedSceneIdentifiers: Set<String> = []

    func body(content: Content) -> some View {
        content.onAppear(perform: applyIfMac)
    }

    private func applyIfMac() {
        guard ProcessInfo.processInfo.isiOSAppOnMac else { return }
        guard let scene = activeWindowScene() else { return }

        let key = scene.session.persistentIdentifier
        guard !Self.sizedSceneIdentifiers.contains(key) else { return }
        Self.sizedSceneIdentifiers.insert(key)

        let preferences = UIWindowScene.GeometryPreferences.Mac(
            systemFrame: CGRect(x: 0, y: 0, width: 1440, height: 900)
        )

        scene.requestGeometryUpdate(preferences) { error in
            #if DEBUG
                os_log(
                    "Failed to set Mac window geometry: %{public}@",
                    log: .default,
                    type: .debug,
                    error.localizedDescription
                )
            #endif
        }
    }

    /// Returns the foreground-active `UIWindowScene`, falling back to any
    /// connected scene if none is yet active. `connectedScenes.first` is
    /// non-deterministic in multi-window scenarios, so we prefer the
    /// foreground one to ensure the geometry update targets the visible window.
    private func activeWindowScene() -> UIWindowScene? {
        let windowScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        return windowScenes.first(where: { $0.activationState == .foregroundActive })
            ?? windowScenes.first
    }
}

extension View {
    /// Apply the Mac-only initial window size. Safe to call on any platform —
    /// no-op on iPhone/iPad. The size is requested at most once per
    /// `UIWindowScene` so subsequent navigation back to the modified view
    /// does not override a user-driven resize.
    func macInitialWindowSize() -> some View {
        modifier(MacWindowSizeModifier())
    }
}
