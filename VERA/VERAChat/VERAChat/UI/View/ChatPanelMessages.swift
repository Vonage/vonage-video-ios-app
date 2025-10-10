//
//  Created by Vonage on 10/10/25.
//

import SwiftUI

struct ChatPanelMessages: View {
    let messages: [UIChatMessage]

    var body: some View {
        ScrollViewReader { proxy in
            let scrollToBottomAction = {
                guard let lastMessage = messages.first else { return }

                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(lastMessage.id)
                }
            }

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    LazyVStack(spacing: 8) {
                        ForEach(messages.reversed()) { message in
                            ChatRow(message: message)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .defaultScrollAnchor(.bottom)
            .onAppear {
                scrollToBottomAction()
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottomAction()
            }
        }
    }
}

// MARK: - Previews
#Preview("Chat Panel") {
    ChatPanelMessages(
        messages: UIChatMessage.sampleMessages
    )
}
