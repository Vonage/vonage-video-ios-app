//
//  Created by Vonage on 21/04/2026.
//

import SwiftUI

// MARK: - Chat Sheet Modifier

struct ChatSheetModifier: ViewModifier {
    @Environment(\.meetingRoomTheme) private var theme

    let isEnabled: Bool
    @Binding var showChat: Bool
    let container: MeetingRoomSDKContainer

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .sheet(
                    isPresented: $showChat,
                    onDismiss: {
                        container.chatBadgeButtonViewModel.chatDidClose()
                    }
                ) {
                    let result = container.chatFactory.make {
                        showChat = false
                    }
                    result.view
                        .opaquePresentationBackground(theme.background)
                }
        } else {
            content
        }
    }
}
