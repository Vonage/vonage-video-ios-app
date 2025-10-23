//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

public struct ParticipantCircleState {
    public let userName: String

    public init(userName: String) {
        self.userName = userName
    }
}

public struct AvatarInitials: View {

    @Environment(\.colorScheme) var colorScheme

    private let state: ParticipantCircleState

    public init(
        state: ParticipantCircleState
    ) {
        self.state = state
    }

    public var body: some View {
        VStack(spacing: 0) {

            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let initialsColor = colorScheme == .dark ? Color.black : Color.white
                let userColor = state.userName.getParticipantColor()

                ZStack {
                    Circle()
                        .frame(width: size, height: size)
                        .foregroundColor(userColor)
                        .animation(.easeInOut(duration: 0.6), value: userColor)

                    Text(state.userName.getInitials())
                        .font(.system(size: size * 0.5))
                        .foregroundColor(initialsColor)
                        .minimumScaleFactor(0.5)
                        .animation(.easeInOut(duration: 0.4), value: state.userName.getInitials())
                        .animation(.easeInOut(duration: 0.3), value: initialsColor)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 1.2).combined(with: .opacity)
                            ))
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AvatarInitials(
            state: .init(
                userName: "Arthur Dent")
        )
        .frame(width: 150, height: 200)

        AvatarInitials(
            state: .init(
                userName: "Ford Prefect")
        )
        .frame(width: 150, height: 200)

        AvatarInitials(
            state: .init(
                userName: "Tricia McMillan")
        )
        .frame(width: 150, height: 200)
    }
    .padding()
    .background(.black)
}
