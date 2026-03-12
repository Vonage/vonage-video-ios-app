//
//  Created by Vonage on 10/10/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

struct ChatRow: View {
    let message: UIChatMessage

    var body: some View {
        HStack {
            AvatarInitials(
                state: .init(
                    userName: message.username
                )
            ).frame(
                width: .avatarSize,
                height: .avatarSize)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.username)
                        .font(.caption)
                        .foregroundColor(VERACommonUIAsset.SemanticColors.secondary.swiftUIColor)
                    Text(message.date)
                        .font(.caption)
                        .foregroundColor(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
                }
                Text(message.message)
                    .font(.body)
                    .foregroundColor(VERACommonUIAsset.SemanticColors.secondary.swiftUIColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

extension CGFloat {
    fileprivate static var avatarSize: CGFloat { 30 }
}

#Preview("Different Cases") {
    VStack(spacing: 8) {
        // Normal message
        ChatRow(
            message: .init(
                username: "Arthur Dent",
                message: "Don't panic! I've got my towel.",
                date: "02:45 PM"))

        // Long username
        ChatRow(
            message: .init(
                username: "Zaphod Beeblebrox IV",
                message: "Hey guys! Just stole a ship. The Infinite Improbability Drive is absolutely froody!",
                date: "03:15 PM"))

        // Very long message
        ChatRow(
            message: .init(
                username: "Deep Thought",
                message:
                    """
                    The Answer to the Great Question of Life, the Universe and Everything is Forty-two.
                    Though I should mention that you're not going to like the question.
                    """,
                date: "7.5M years ago"))

        // Short message
        ChatRow(
            message: .init(
                username: "Marvin",
                message: "Life? Don't talk to me about life.",
                date: "Now"))
    }
    .padding()
}

#Preview("Dark color scheme") {
    VStack(spacing: 8) {
        ChatRow(
            message: .init(
                username: "Ford Prefect",
                message: "Time is an illusion. Lunchtime doubly so.",
                date: "10:30 AM"))

        ChatRow(
            message: .init(
                username: "Slartibartfast",
                message: "I'd much rather be happy than right any day.",
                date: "10:31 AM"))

    }
    .preferredColorScheme(.dark)
    .padding()
}
