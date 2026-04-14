//
//  Created by Vonage on 14/04/2026.
//

import Combine
import SwiftUI
import VERACommonUI
import VERADomain

public struct ChatBadgeComponentButton: View {
    @ObservedObject private var viewModel: ChatBadgeButtonViewModel
    private let onShowChat: () -> Void

    private var unreadMessagesCount: Int { viewModel.unreadMessagesCount }

    public init(viewModel: ChatBadgeButtonViewModel, onShowChat: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onShowChat = onShowChat
    }

    public var body: some View {
        ChatBadgeButton(
            unreadMessagesCount: unreadMessagesCount,
            onShowChat: onShowChat
        )
    }
}
