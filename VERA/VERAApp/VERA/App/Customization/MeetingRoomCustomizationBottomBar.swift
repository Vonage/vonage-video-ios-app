//
//  Created by Vonage on 30/6/26.
//

import SwiftUI
import VERAMeetingRoom

struct MeetingRoomCustomizationBottomBar: View {
    let context: MeetingRoomBottomBarContext

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    actionButton(context.controls.microphone)
                    actionButton(context.controls.camera)
                    actionButton(context.controls.layout)

                    if let participants = context.controls.participants {
                        actionButton(participants)
                    }

                    Divider()
                        .frame(height: 28)

                    presentationButton(style: .dialog, image: Image(systemName: "exclamationmark.bubble.fill"))
                    presentationButton(style: .overlay, image: Image(systemName: "rectangle.on.rectangle"))
                    presentationButton(style: .sheet, image: Image(systemName: "rectangle.bottomhalf.inset.filled"))
                }
            }

            actionButton(context.controls.endCall, role: .destructive)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .accessibilityIdentifier("meeting-room-custom-bottom-bar")
    }

    func presentationButton(style: MeetingRoomPresentationRequest.Style, image: Image) -> some View {
        actionButton(
            image: image,
            isActive: false,
            accessibilityIdentifier: "meeting-room-custom-bottom-bar-\(style)-presentation"
        ) {
            context.presentationHandler.present(
                MeetingRoomPresentationRequest(
                    id: "custom-bottom-bar-\(style)",
                    style: style,
                    title: "\(style.title) presentation",
                    message: "Presented from the custom bottom bar."
                )
            )
        }
    }

    func actionButton(_ control: MeetingRoomBottomBarControl, role: ButtonRole? = nil) -> some View {
        actionButton(
            image: control.image,
            isActive: control.isActive,
            accessibilityIdentifier: control.accessibilityIdentifier ?? control.id,
            role: role,
            action: control.action
        )
    }

    func actionButton(
        image: Image,
        isActive: Bool,
        accessibilityIdentifier: String,
        role: ButtonRole? = nil,
        action: @escaping @MainActor () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            image
                .frame(width: 44, height: 44)
                .foregroundStyle(role == .destructive ? .white : .primary)
                .background(role == .destructive ? Color.red : activeBackgroundColor(isActive))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    func activeBackgroundColor(_ isActive: Bool) -> Color {
        isActive ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.15)
    }
}

extension MeetingRoomPresentationRequest.Style {
    fileprivate var title: String {
        switch self {
        case .dialog: "Dialog"
        case .overlay: "Overlay"
        case .sheet: "Sheet"
        }
    }
}
