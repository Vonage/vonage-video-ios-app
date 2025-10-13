//
//  Created by Vonage on 10/10/25.
//

import SwiftUI

struct ChatPanelMessages: View {
    let messages: [UIChatMessage]

    private var lastMessageId: UUID? {
        messages.last?.id
    }

    var body: some View {
        ScrollViewReader { proxy in
            let scrollToBottomAction = {
                guard let messageId = lastMessageId else { return }

                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(messageId, anchor: .bottom)
                }
            }

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            ChatRow(message: message)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
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
