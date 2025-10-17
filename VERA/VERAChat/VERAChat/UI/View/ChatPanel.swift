//
//  Created by Vonage on 10/10/25.
//

import SwiftUI
import VERACommonUI

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
        .background(.systemBackground)
    }
}

struct ChatPanelInput: View {
    let onSendMessage: (String) -> Void
    @State private var messageText = ""

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField(
                "Type a message...",
                text: $messageText,
                prompt: Text("Type a message...").secondaryForeground(),
                axis: .vertical
            )
            .lineLimit(1...3)

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .foregroundColor(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accent)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(GlassBackground())
    }

    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }

        onSendMessage(trimmedMessage)
        messageText = ""
    }
}

extension Text {
    func secondaryForeground() -> Text {
        if #available(iOS 17.0, *) {
            return self.foregroundStyle(.gray)
        } else {
            return self.foregroundColor(.gray)
        }
    }
}

struct GlassBackground: View {
    var body: some View {
        #if os(macOS)
            RoundedRectangle(cornerRadius: 16)
                .fill(.gray4.opacity(0.8))
        #else
            Group {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 16)
                        .glassEffect(in: .rect(cornerRadius: 16.0))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.gray4.opacity(0.8))
                }
            }
        #endif
    }

    #if !os(macOS)
        @available(iOS 26.0, *)
        private func glassEffectBackground() -> some View {
            RoundedRectangle(cornerRadius: 16)
                .glassEffect(in: .rect(cornerRadius: 16.0))
        }
    #endif
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
