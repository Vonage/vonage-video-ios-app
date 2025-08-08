//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

struct AvatarGroup: View {
    let users: [AvatarGroupUser]
    let maxVisible: Int
    let size: CGFloat
    let spacing: CGFloat

    init(
        users: [AvatarGroupUser],
        maxVisible: Int = 4,
        size: CGFloat = 40,
        spacing: CGFloat = -8
    ) {
        self.users = users
        self.maxVisible = maxVisible
        self.size = size
        self.spacing = spacing
    }

    private var visibleUsers: [AvatarGroupUser] {
        Array(users.prefix(maxVisible))
    }

    private var hiddenCount: Int {
        max(0, users.count - maxVisible)
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(visibleUsers.enumerated()), id: \.element.id) { index, user in
                AvatarView(
                    user: user,
                    size: size
                )
                .zIndex(Double(visibleUsers.count - index))
            }

            if hiddenCount > 0 {
                OverflowCountAvatar(
                    count: hiddenCount,
                    size: size
                )
                .zIndex(0)
            }
        }
    }
}

// MARK: - Avatar individual
struct AvatarView: View {
    let user: AvatarGroupUser
    let size: CGFloat

    private var initials: String {
        let names = user.name.split(separator: " ")
        if names.count >= 2 {
            return "\(names[0].prefix(1))\(names[1].prefix(1))".uppercased()
        } else {
            return String(user.name.prefix(2)).uppercased()
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(user.backgroundColor)
                .frame(width: size, height: size)

            Text(initials)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(user.textColor)
        }
        .overlay(
            Circle()
                .stroke(Color(.uiSystemBackground), lineWidth: 2)
        )
    }
}

// MARK: - Avatar contador de overflow
struct OverflowCountAvatar: View {
    let count: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: size, height: size)

            Text("+\(count)")
                .font(.system(size: size * 0.35, weight: .medium))
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke(Color(.uiSystemBackground), lineWidth: 2)
        )
    }
}

struct AvatarGroupUser: Identifiable {
    let id: String
    let name: String
    let backgroundColor: Color
    let textColor: Color

    init(
        id: String = UUID().uuidString,
        name: String,
        textColor: Color = .white
    ) {
        self.id = id
        self.name = name
        self.backgroundColor = name.getParticipantColor()
        self.textColor = textColor
    }
}

struct AdvancedAvatarGroup: View {
    let users: [AvatarGroupUser]
    let maxVisible: Int
    let size: CGFloat
    let spacing: CGFloat
    let showBorder: Bool
    let onTap: ((AvatarGroupUser) -> Void)?
    let onOverflowTap: (([AvatarGroupUser]) -> Void)?

    init(
        users: [AvatarGroupUser],
        maxVisible: Int = 4,
        size: CGFloat = 40,
        spacing: CGFloat = -8,
        showBorder: Bool = true,
        onTap: ((AvatarGroupUser) -> Void)? = nil,
        onOverflowTap: (([AvatarGroupUser]) -> Void)? = nil
    ) {
        self.users = users
        self.maxVisible = maxVisible
        self.size = size
        self.spacing = spacing
        self.showBorder = showBorder
        self.onTap = onTap
        self.onOverflowTap = onOverflowTap
    }

    private var visibleUsers: [AvatarGroupUser] {
        Array(users.prefix(maxVisible))
    }

    private var hiddenUsers: [AvatarGroupUser] {
        Array(users.dropFirst(maxVisible))
    }

    private var hiddenCount: Int {
        hiddenUsers.count
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(visibleUsers.enumerated()), id: \.element.id) { index, user in
                AvatarView(
                    user: user,
                    size: size
                )
                .zIndex(Double(visibleUsers.count - index))
                .onTapGesture {
                    onTap?(user)
                }
            }

            if hiddenCount > 0 {
                OverflowCountAvatar(
                    count: hiddenCount,
                    size: size
                )
                .zIndex(0)
                .onTapGesture {
                    onOverflowTap?(hiddenUsers)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: users.count)
    }
}

#if DEBUG
    extension PreviewData {
        static let users: [AvatarGroupUser] = [
            AvatarGroupUser(name: "Arthur Dent"),
            AvatarGroupUser(name: "Ford Prefect"),
            AvatarGroupUser(name: "Zaphod Beeblebrox"),
            AvatarGroupUser(name: "Trillian"),
            AvatarGroupUser(name: "Marvin"),
            AvatarGroupUser(name: "Slartibartfast"),
            AvatarGroupUser(name: "Eddie"),
            AvatarGroupUser(name: "Deep Thought"),
        ]
    }
#endif

#Preview("Avatar Group - Few Users") {
    VStack(spacing: 20) {
        AvatarGroup(users: Array(PreviewData.users.prefix(3)))

        AvatarGroup(
            users: PreviewData.users,
            maxVisible: 3,
            size: 50
        )

        AvatarGroup(
            users: PreviewData.users,
            maxVisible: 5,
            size: 60,
            spacing: -12
        )
    }
    .padding()
}
