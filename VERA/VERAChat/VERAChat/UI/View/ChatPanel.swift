//
//  Created by Vonage on 10/10/25.
//

import SwiftUI

public struct ChatPanel: View {
    public let messages: [UIChatMessage]
    public let onSendMessage: (String) -> Void

    public init(
        messages: [UIChatMessage],
        onSendMessage: @escaping (String) -> Void
    ) {
        self.messages = messages
        self.onSendMessage = onSendMessage
    }

    public var body: some View {
        VStack(spacing: 0) {
            ChatPanelMessages(messages: messages)

            ChatPanelInput(onSendMessage: onSendMessage)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
        }
        .background(Color.primary.colorInvert())
    }
}

struct ChatPanelInput: View {
    let onSendMessage: (String) -> Void
    @State private var messageText = ""

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Text Input
            TextField("Type a message...", text: $messageText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...3)

            // Send Button
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .foregroundColor(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }

        onSendMessage(trimmedMessage)
        messageText = ""
    }
}

// MARK: - Previews
#Preview("Chat Panel") {
    ChatPanel(
        messages: UIChatMessage.sampleMessages,
        onSendMessage: { message in print("Send: \(message)") }
    )
}

#Preview("Chat Input Only") {
    VStack {
        Spacer()
        ChatPanelInput { message in
            print("Sending: \(message)")
        }
        .background(Color.gray.opacity(0.1))
        .padding()
    }
}
