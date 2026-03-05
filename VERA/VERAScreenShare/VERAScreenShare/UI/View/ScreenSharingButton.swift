//
//  Created by Vonage on 1/3/26.
//

#if os(iOS)
    import Combine
    import ReplayKit
    import SwiftUI
    import VERACommonUI

    /// Represents the state of the screen sharing button.
    public enum ScreenSharingButtonState: Equatable {
        /// Screen sharing is not active.
        case idle
        /// Screen sharing is active.
        case sharing

        /// Whether screen sharing is currently active.
        public var isSharing: Bool {
            self == .sharing
        }
    }

    /// A button that triggers the system broadcast picker for screen sharing.
    ///
    /// Uses `OngoingActivityControlImageButton` from VERACommonUI for consistent styling
    /// with other meeting room toolbar buttons. Overlays a zero-frame
    /// `RPSystemBroadcastPickerView` and programmatically triggers its internal button on tap.
    public struct ScreenSharingButton: View {

        // MARK: - Properties

        private let state: ScreenSharingButtonState
        private let preferredExtension: String?
        private let actionTrigger = PassthroughSubject<Void, Never>()

        // MARK: - Initialization

        /// Creates a screen sharing button.
        /// - Parameters:
        ///   - state: The current state of the button.
        ///   - preferredExtension: The bundle ID of the Broadcast Upload Extension.
        public init(
            state: ScreenSharingButtonState = .idle,
            preferredExtension: String? = "com.vonage.VERA.BroadcastExtension"
        ) {
            self.state = state
            self.preferredExtension = preferredExtension
        }

        // MARK: - Body

        public var body: some View {
            ZStack {
                OngoingActivityControlImageButton(
                    isActive: state.isSharing,
                    image: Image(systemName: "rectangle.on.rectangle"),
                    action: {
                        actionTrigger.send()
                    }
                )
                .accessibilityLabel(String(localized: "Share Screen", bundle: .veraScreenShare))
                .accessibilityHint(
                    state.isSharing
                        ? String(localized: "Stop screen sharing", bundle: .veraScreenShare)
                        : String(localized: "Start screen sharing", bundle: .veraScreenShare)
                )

                BroadcastPickerRepresentable(
                    preferredExtension: preferredExtension,
                    actionTrigger: actionTrigger
                )
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Preview

    #if DEBUG
        #Preview("Default") {
            VStack(spacing: 20) {
                ScreenSharingButton(state: .idle)
                ScreenSharingButton(state: .sharing)
            }
            .padding()
            .background(.white)
        }
    #endif
#endif
