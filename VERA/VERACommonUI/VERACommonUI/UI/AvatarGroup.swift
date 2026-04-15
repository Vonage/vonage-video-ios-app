//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

/// Layout constants for the avatar group component.
private enum AvatarGroupConstants {
    /// Default maximum number of visible avatars.
    static let defaultMaxVisible: Int = 4
    /// Default avatar circle diameter.
    static let defaultSize: CGFloat = 40
    /// Default overlap spacing between avatars.
    static let defaultSpacing: CGFloat = -8
    /// Scale factor for the initials font relative to avatar size.
    static let initialsFontScale: CGFloat = 0.4
    /// Scale factor for the overflow count font relative to avatar size.
    static let overflowFontScale: CGFloat = 0.35
    /// Width of the border stroke around each avatar.
    static let strokeWidth: CGFloat = 2
    /// Opacity of the overflow count circle background.
    static let overflowBackgroundOpacity: Double = 0.3
    /// Duration of the avatar group animation.
    static let animationDuration: Double = 0.3
}

public struct AvatarGroup: View {
    let users: [AvatarGroupUser]
    let maxVisible: Int
    let size: CGFloat
    let spacing: CGFloat

    public init(
        users: [AvatarGroupUser],
        maxVisible: Int = AvatarGroupConstants.defaultMaxVisible,
        size: CGFloat = AvatarGroupConstants.defaultSize,
        spacing: CGFloat = AvatarGroupConstants.defaultSpacing
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

    public var body: some View {
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
                .font(.system(size: size * AvatarGroupConstants.initialsFontScale, weight: .medium))
                .foregroundColor(user.textColor)
        }
        .overlay(
            Circle()
                .stroke(
                    VERACommonUIAsset.SemanticColors.surface.swiftUIColor,
                    lineWidth: AvatarGroupConstants.strokeWidth
                )
        )
    }
}

// MARK: - Avatar overflow counter
struct OverflowCountAvatar: View {
    let count: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(AvatarGroupConstants.overflowBackgroundOpacity))
                .frame(width: size, height: size)

            Text("+\(count)")
                .font(.system(size: size * AvatarGroupConstants.overflowFontScale, weight: .medium))
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke(
                    VERACommonUIAsset.SemanticColors.surface.swiftUIColor,
                    lineWidth: AvatarGroupConstants.strokeWidth
                )
        )
    }
}

public struct AvatarGroupUser: Identifiable {
    public let id: String
    public let name: String
    public let backgroundColor: Color
    public let textColor: Color

    public init(
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
        maxVisible: Int = AvatarGroupConstants.defaultMaxVisible,
        size: CGFloat = AvatarGroupConstants.defaultSize,
        spacing: CGFloat = AvatarGroupConstants.defaultSpacing,
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
        .animation(.easeInOut(duration: AvatarGroupConstants.animationDuration), value: users.count)
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
#endif
