//
//  Created by Vonage on 26/2/26.
//

#if os(iOS)
import ReplayKit
import SwiftUI

/// A SwiftUI wrapper around `RPSystemBroadcastPickerView` that lets the user start
/// or stop an iOS system broadcast (screen share) directly from within the app.
///
/// The broadcast picker is pre-configured with the VERA Broadcast Upload Extension
/// so the system sheet pre-selects the correct extension.
public struct ScreenShareView: UIViewRepresentable {
    private let broadcastExtensionBundleId: String?
    private let showsMicrophoneButton: Bool
    
    /// Creates a screen-share trigger view.
    ///
    /// - Parameters:
    ///   - viewModel: The view model supplying the extension bundle identifier and mic button preference.
    public init(
        broadcastExtensionBundleId: String? = "com.vonage.VERA.BroadcastExtension",
        showsMicrophoneButton: Bool = false
    ) {
        self.broadcastExtensionBundleId = broadcastExtensionBundleId
        self.showsMicrophoneButton = showsMicrophoneButton
    }

    public func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let pickerView = RPSystemBroadcastPickerView(frame: .zero)
        pickerView.preferredExtension = broadcastExtensionBundleId
        pickerView.showsMicrophoneButton = showsMicrophoneButton
        return pickerView
    }

    public func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {
    }
}
#endif
