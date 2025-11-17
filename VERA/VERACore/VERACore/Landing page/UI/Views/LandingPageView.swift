//
//  Created by Vonage on 7/8/25.
//

import Combine
import SwiftUI
import VERACommonUI

public struct LandingPageView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    public let onHandleNewRoom: () -> Void
    public let onJoinRoom: (String) -> Void
    public let onNavigateToWaitingRoom: (String) -> Void

    public init(
        onHandleNewRoom: @escaping () -> Void,
        onJoinRoom: @escaping (String) -> Void,
        onNavigateToWaitingRoom: @escaping (String) -> Void
    ) {
        self.onHandleNewRoom = onHandleNewRoom
        self.onJoinRoom = onJoinRoom
        self.onNavigateToWaitingRoom = onNavigateToWaitingRoom
    }

    public var body: some View {
        Group {
            if verticalSizeClass == .compact {
                HorizontalLandingContentView(
                    onHandleNewRoom: onHandleNewRoom,
                    onJoinRoom: onJoinRoom)
            } else if horizontalSizeClass == .compact {
                VerticalLandingContentView(
                    onHandleNewRoom: onHandleNewRoom,
                    onJoinRoom: onJoinRoom)
            } else {
                HorizontalLandingContentView(
                    onHandleNewRoom: onHandleNewRoom,
                    onJoinRoom: onJoinRoom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct HorizontalLandingContentView: View {

    public let onHandleNewRoom: () -> Void
    public let onJoinRoom: (String) -> Void

    public init(
        onHandleNewRoom: @escaping () -> Void,
        onJoinRoom: @escaping (String) -> Void
    ) {
        self.onHandleNewRoom = onHandleNewRoom
        self.onJoinRoom = onJoinRoom
    }

    public var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Side
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    BannerLogo()
                    Spacer()
                }
                .padding()

                Spacer()
                LandingPageWelcome()
                    .frame(maxWidth: .infinity)
                Spacer()

                Color.clear
                    .frame(height: 60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: - Right Side
            VStack(alignment: .center, spacing: 0) {
                Color.clear
                    .frame(height: 60)

                Spacer()

                RoomJoinContainer(
                    onHandleNewRoom: onHandleNewRoom,
                    onJoinRoom: onJoinRoom
                )
                .padding(.horizontal)
                .frame(maxWidth: .infinity)

                Spacer()

                HStack(spacing: 8) {
                    GHRepoButton()
                    Text("Vonage Video Reference Application")
                        .adaptiveFont(.bodyBase)
                        .foregroundColor(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(VERACommonUIAsset.SemanticColors.background.swiftUIColor)
        }
    }
}

public struct VerticalLandingContentView: View {

    public let onHandleNewRoom: () -> Void
    public let onJoinRoom: (String) -> Void

    public init(
        onHandleNewRoom: @escaping () -> Void,
        onJoinRoom: @escaping (String) -> Void
    ) {
        self.onHandleNewRoom = onHandleNewRoom
        self.onJoinRoom = onJoinRoom
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            LandingPageWelcome()
                .padding(.bottom, 40)

            RoomJoinContainer(
                onHandleNewRoom: onHandleNewRoom,
                onJoinRoom: onJoinRoom
            )
            .frame(maxWidth: .infinity)
            Spacer()
        }
    }
}

#Preview {
    LandingPageView(
        onHandleNewRoom: {},
        onJoinRoom: { _ in },
        onNavigateToWaitingRoom: { _ in })
}
