//
//  Created by Vonage on 11/5/26.
//

import Foundation
import SwiftUI
import UIKit

/// Sets the initial window size and minimum size on macOS ("Designed for iPad on Mac").
///
/// The Vera waiting room and meeting room are laid out for a wide window on Mac
/// — splitting the screen 50/50 between preview and the join form, with a
/// performance HUD overlay. The system's default iPad-on-Mac window size is too
/// small for that to feel right. We bump the initial size and lock a sensible
/// minimum so the layout doesn't degrade if the user resizes down.
///
/// No-op on iOS devices.
struct MacWindowSizeModifier: ViewModifier {

    func body(content: Content) -> some View {
        content.onAppear(perform: applyIfMac)
    }

    private func applyIfMac() {
        guard ProcessInfo.processInfo.isiOSAppOnMac else { return }
        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first
        else { return }

        // `UIWindowScene.GeometryPreferences.Mac` only exposes the initial
        // system frame — minimum/maximum size aren't configurable here.
        let preferences = UIWindowScene.GeometryPreferences.Mac(
            systemFrame: CGRect(x: 0, y: 0, width: 1440, height: 900)
        )

        scene.requestGeometryUpdate(preferences) { error in
            #if DEBUG
                print("Failed to set Mac window geometry: \(error.localizedDescription)")
            #endif
        }
    }
}

extension View {
    /// Apply the Mac-only initial window size + minimum. Safe to call on any
    /// platform — it's a no-op on iPhone/iPad.
    func macInitialWindowSize() -> some View {
        modifier(MacWindowSizeModifier())
    }
}
