//
//  Created by Vonage on 10/10/25.
//

import SwiftUI

/// Layout constants for the chat messages panel.
private enum ChatPanelMessagesConstants {
    /// Duration of the scroll-to-bottom animation.
    static let scrollAnimationDuration: Double = 0.3
    /// Vertical spacing between message rows.
    static let messageSpacing: CGFloat = 8
    /// Horizontal padding around the message list.
    static let horizontalPadding: CGFloat = 16
    /// Vertical padding around the message list.
    static let verticalPadding: CGFloat = 8
}

struct ChatPanelMessages: View {
    let messages: [UIChatMessage]

    private var lastMessageId: Int? {
        messages.last?.id
    }

    var body: some View {
        ScrollViewReader { proxy in
            let scrollToBottomAction = {
                guard let messageId = lastMessageId else { return }

                withAnimation(.easeInOut(duration: ChatPanelMessagesConstants.scrollAnimationDuration)) {
                    proxy.scrollTo(messageId, anchor: .bottom)
                }
            }

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    LazyVStack(spacing: ChatPanelMessagesConstants.messageSpacing) {
                        ForEach(messages) { message in
                            ChatRow(message: message)
                        }
                    }
                    .padding(.horizontal, ChatPanelMessagesConstants.horizontalPadding)
                    .padding(.vertical, ChatPanelMessagesConstants.verticalPadding)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .modifier(ConditionalScrollAnchor())
            .onChange(of: lastMessageId) { messageId in
                guard messageId != nil else { return }

                DispatchQueue.main.async {
                    scrollToBottomAction()
                }
            }
        }
    }
}

struct ConditionalScrollAnchor: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.defaultScrollAnchor(.bottom)
        } else {
            content
        }
    }
}

// MARK: - Previews
#Preview("Chat Panel") {
    ChatPanelMessages(
        messages: UIChatMessage.sampleMessages
    )
}
