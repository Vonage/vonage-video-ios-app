//
//  Created by Vonage on 5/3/26.
//

#if os(iOS)
    import Combine
    import ReplayKit
    import SwiftUI
    import VERACommonUI

    /// A minimal `UIViewRepresentable` wrapping `RPSystemBroadcastPickerView` with a zero frame.
    /// The picker is invisible — it exists only so its internal UIButton can be triggered programmatically.
    public struct BroadcastPickerRepresentable: UIViewRepresentable {
        let preferredExtension: String?
        let actionTrigger: PassthroughSubject<Void, Never>

        public init(
            preferredExtension: String?,
            actionTrigger: PassthroughSubject<Void, Never>
        ) {
            self.preferredExtension = preferredExtension
            self.actionTrigger = actionTrigger
        }

        public func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        public func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
            let picker = RPSystemBroadcastPickerView(frame: .zero)
            picker.preferredExtension = preferredExtension
            picker.showsMicrophoneButton = false

            DispatchQueue.main.async {
                if let button = picker.subviews.compactMap({ $0 as? UIButton }).first {
                    context.coordinator.broadcastButton = button
                }
            }

            actionTrigger
                .sink { context.coordinator.broadcastButton?.sendActions(for: .touchUpInside) }
                .store(in: &context.coordinator.cancellables)

            return picker
        }

        public func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {
        }

        public class Coordinator {
            var broadcastButton: UIButton?
            var cancellables = Set<AnyCancellable>()
        }
    }

#endif
