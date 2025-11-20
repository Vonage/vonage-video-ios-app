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
        .background(VERACommonUIAsset.SemanticColors.surface.swiftUIColor)
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
        HorizontalContentView {
            LandingPageWelcome()
        } rightSide: {
            CardView {
                RoomJoinContainer(
                    onHandleNewRoom: onHandleNewRoom,
                    onJoinRoom: onJoinRoom
                )
            }
            .padding(.horizontal)
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
        VerticalContentView {
            LandingPageWelcome()
                .padding(.horizontal)
                .padding()
        } bottomSide: {
            RoomJoinContainer(
                onHandleNewRoom: onHandleNewRoom,
                onJoinRoom: onJoinRoom
            )
            .padding()
        }
    }
}

#Preview {
    LandingPageView(
        onHandleNewRoom: {},
        onJoinRoom: { _ in },
        onNavigateToWaitingRoom: { _ in })
}
