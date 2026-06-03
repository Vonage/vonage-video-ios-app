//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

typealias ViewNameID = String

enum JoinExistingRoomUIIDs {
    static let joinButton: ViewNameID = "JoinButton"
}

enum RoomNameState {
    case initial, valid, invalid
}

/// Layout constants for the join-existing-room form.
private enum JoinExistingRoomConstants {
    /// Vertical spacing between form elements.
    static let fieldSpacing: CGFloat = 8
    /// Bottom padding for the section title.
    static let titleBottomPadding: CGFloat = 8
    /// Vertical padding around the join button.
    static let joinButtonVerticalPadding: CGFloat = 16
    /// Spring animation response for field state changes.
    static let springResponse: Double = 0.3
    /// Spring animation damping fraction.
    static let springDamping: Double = 0.7
    /// Duration of the room-state validation animation.
    static let validationAnimationDuration: Double = 0.2
}

struct JoinExistingRoom: View {

    @State var roomName: RoomName = ""
    @State private var roomState = VonageTextFieldState.initial

    let onJoinRoom: (String) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: JoinExistingRoomConstants.fieldSpacing) {
                Text("Join existing meeting", bundle: .veraCore)
                    .adaptiveFont(.heading4)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                    .padding(.bottom, JoinExistingRoomConstants.titleBottomPadding)

                VonageTextField(
                    placeholder: String(localized: "Room name", bundle: .veraCore),
                    text: $roomName,
                    state: roomState,
                    forceLowercase: true,
                    accessibilityIdentifier: LandingPageAccessibilityID.roomNameInput
                )

                JoinButton(color: joinColor) {
                    roomState = getRoomState(true)
                    onJoinRoom(roomName)
                }
                .id(JoinExistingRoomUIIDs.joinButton)
                .padding(.vertical, JoinExistingRoomConstants.joinButtonVerticalPadding)
                .animation(
                    .spring(
                        response: JoinExistingRoomConstants.springResponse,
                        dampingFraction: JoinExistingRoomConstants.springDamping
                    ), value: roomState
                )
            }
        }
        .onChange(of: roomName) { _ in
            withAnimation(.easeInOut(duration: JoinExistingRoomConstants.validationAnimationDuration)) {
                roomState = getRoomState()
            }
        }
    }

    private var borderColor: Color {
        switch getRoomState() {
        case .initial:
            return VERACommonUIAsset.SemanticColors.primary.swiftUIColor
        case .valid:
            return VERACommonUIAsset.SemanticColors.primary.swiftUIColor
        case .invalid:
            return .red
        }
    }

    private var joinColor: Color {
        VERACommonUIAsset.SemanticColors.primary.swiftUIColor
    }

    private func getRoomState(_ joinPressed: Bool = false) -> VonageTextFieldState {
        if joinPressed {
            if roomName.isEmpty {
                return .invalid(InvalidRoomName.empty.rawValue)
            } else {
                return roomName.isValidRoomName
                    ? .valid : .invalid(InvalidRoomName.containsSpaceOrSpecialCharacter.rawValue)
            }
        }
        if roomName.isEmpty {
            return .initial
        } else {
            return roomName.isValidRoomName
                ? .valid : .invalid(InvalidRoomName.containsSpaceOrSpecialCharacter.rawValue)
        }
    }
}

enum InvalidRoomName: String {
    case empty = "Room name cannot be empty"
    case containsSpaceOrSpecialCharacter = "Cannot be empty, contain spaces or special characters"
}

#Preview {
    JoinExistingRoom { _ in }
}
