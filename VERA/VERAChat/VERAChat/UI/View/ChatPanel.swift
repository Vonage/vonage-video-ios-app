//
//  Created by Vonage on 10/10/25.
//

import SwiftUI
import VERACommonUI

/// Layout constants for the chat panel.
private enum ChatPanelConstants {
    /// Horizontal padding around the input area.
    static let inputAreaHorizontalPadding: CGFloat = 8
    /// Vertical padding around the input area.
    static let inputAreaVerticalPadding: CGFloat = 8
    /// Spacing between the text field and send button.
    static let inputFieldSpacing: CGFloat = 12
    /// Inner padding of the input container.
    static let inputContainerPadding: CGFloat = 12
    /// Corner radius for the glass background.
    static let glassCornerRadius: CGFloat = 16
    /// Background opacity for the glass effect fallback.
    static let glassBackgroundOpacity: Double = 0.8
}

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
                .padding(.horizontal, ChatPanelConstants.inputAreaHorizontalPadding)
                .padding(.vertical, ChatPanelConstants.inputAreaVerticalPadding)
        }
        .background(VERACommonUIAsset.SemanticColors.surface.swiftUIColor)
    }
}

struct ChatPanelInput: View {
    let onSendMessage: (String) -> Void
    @State private var messageText = ""

    var body: some View {
        HStack(alignment: .bottom, spacing: ChatPanelConstants.inputFieldSpacing) {
            TextField(
                "Type a message...",
                text: $messageText,
                prompt: Text("Type a message...").secondaryForeground(),
                axis: .vertical
            )
            .lineLimit(1...3)

            Button(action: sendMessage) {
                VERACommonUIAsset.Images.messageSentSolid.swiftUIImage
                    .font(.title2)
                    .foregroundColor(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? .gray : VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(ChatPanelConstants.inputContainerPadding)
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
            return self.foregroundStyle(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
        } else {
            return self.foregroundColor(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
        }
    }
}

struct GlassBackground: View {
    var body: some View {
        #if os(macOS)
            RoundedRectangle(cornerRadius: ChatPanelConstants.glassCornerRadius)
                .fill(
                    VERACommonUIAsset.Colors.vGray4.swiftUIColor
                        .opacity(ChatPanelConstants.glassBackgroundOpacity))
        #else
            Group {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: ChatPanelConstants.glassCornerRadius)
                        .glassEffect(in: .rect(cornerRadius: ChatPanelConstants.glassCornerRadius))
                } else {
                    RoundedRectangle(cornerRadius: ChatPanelConstants.glassCornerRadius)
                        .fill(
                            VERACommonUIAsset.Colors.vGray4.swiftUIColor
                                .opacity(ChatPanelConstants.glassBackgroundOpacity))
                }
            }
        #endif
    }
}

// MARK: - Previews
#Preview("Chat Panel") {
    ChatPanel(
        messages: UIChatMessage.sampleMessages
    ) { _ in
    }
}

#Preview("Chat Input Only") {
    VStack {
        Spacer()
        ChatPanelInput { _ in
        }
        .background(Color.gray.opacity(0.1))
        .padding()
    }
}
