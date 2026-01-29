//
//  Created by Vonage on 27/01/2026.
//

import AVKit
import Foundation
import SwiftUI

public struct AudioRoutePickerView: UIViewRepresentable {
    public init() {}
    public func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.prioritizesVideoDevices = false  // Only show audio routes
        view.activeTintColor = .systemBlue
        view.tintColor = .white
        return view
    }
    public func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
