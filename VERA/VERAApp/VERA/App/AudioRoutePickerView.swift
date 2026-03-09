//
//  Created by Vonage on 30/01/2026.
//

import AVKit
import Foundation
import SwiftUI
import UIKit
import VERACommonUI

public struct AudioRoutePickerView: UIViewRepresentable {
    public init() {}

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
        button.tintColor = .white
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
