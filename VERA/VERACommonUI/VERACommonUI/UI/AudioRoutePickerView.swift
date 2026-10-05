//
//  Created by Vonage on 30/01/2026.
//

#if canImport(UIKit)
    import AVKit
    import Foundation
    import SwiftUI
    import UIKit

    /// System audio-output route selector (AirPlay / speaker / Bluetooth / headphones).
    ///
    /// Wraps the native `AVRoutePickerView` (kept invisible) beneath a custom icon overlay so it
    /// matches the app styling while delegating route selection to the system. Shared by the
    /// meeting room top bar and the waiting room toolbar.
    public struct AudioRoutePickerView: UIViewRepresentable {
        private let iconColor: UIColor

        /// - Parameter iconColor: Tint applied to the speaker icon. Defaults to `.white` for the
        ///   meeting room's dark top bar; pass an adaptive color for light backgrounds.
        public init(iconColor: UIColor = .white) {
            self.iconColor = iconColor
        }

        public func makeUIView(context: Context) -> UIView {
            let container = UIView()

            let routePicker = AVRoutePickerView()
            routePicker.translatesAutoresizingMaskIntoConstraints = false
            routePicker.prioritizesVideoDevices = false
            routePicker.tintColor = .clear
            routePicker.activeTintColor = .clear
            container.addSubview(routePicker)

            let button = UIButton(type: .custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.isUserInteractionEnabled = false
            button.setImage(VERACommonUIAsset.Images.audioMidLine.image, for: .normal)
            button.tintColor = iconColor
            container.addSubview(button)

            NSLayoutConstraint.activate([
                routePicker.topAnchor.constraint(equalTo: container.topAnchor),
                routePicker.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                routePicker.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                routePicker.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                button.topAnchor.constraint(equalTo: container.topAnchor),
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
            return container
        }

        public func updateUIView(_ uiView: UIView, context: Context) {}
    }

    extension AudioRoutePickerView {
        /// Stable identifier for the route-picker button, shared by every context that hosts it
        /// (meeting room top bar, waiting room toolbar) so the id stays consistent.
        public static let viewID = "AudioRouteSelector"

        /// Standard fixed-size route-picker button used across the app.
        ///
        /// Centralises the sizing so callers (meeting room top bar, waiting room toolbar) don't
        /// each repeat the frame. Defaults to a 44x44 tappable target.
        public static func button(size: CGFloat = 44, iconColor: UIColor = .white) -> some View {
            AudioRoutePickerView(iconColor: iconColor)
                .frame(width: size, height: size)
        }
    }
#endif
