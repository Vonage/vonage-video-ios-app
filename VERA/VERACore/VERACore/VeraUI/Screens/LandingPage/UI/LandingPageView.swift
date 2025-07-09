//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import Combine

public struct LandingPageView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    public let onHandleNewRoom: ()->Void
    public let onJoinRoom: (String)->Void
    public let onNavigateToWaitingRoom: (String)->Void
    
    public init(onHandleNewRoom: @escaping () -> Void,
         onJoinRoom: @escaping (String) -> Void,
         onNavigateToWaitingRoom: @escaping (String) -> Void) {
        self.onHandleNewRoom = onHandleNewRoom
        self.onJoinRoom = onJoinRoom
        self.onNavigateToWaitingRoom = onNavigateToWaitingRoom
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Banner()
                .frame(height: 70)
                .padding(.horizontal, 8)
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
            .frame(maxHeight: .infinity)
        }
    }
}

public struct HorizontalLandingContentView: View {
    
    public let onHandleNewRoom: ()->Void
    public let onJoinRoom: (String)->Void
    
    public init(onHandleNewRoom: @escaping () -> Void,
         onJoinRoom: @escaping (String) -> Void) {
        self.onHandleNewRoom = onHandleNewRoom
        self.onJoinRoom = onJoinRoom
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 20) {
            LandingPageWelcome()
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)
            
            RoomJoinContainer(
                onHandleNewRoom: onHandleNewRoom,
                onJoinRoom: onJoinRoom)
                .frame(maxWidth: .infinity)
        }
    }
}

public struct VerticalLandingContentView: View {
    
    public let onHandleNewRoom: ()->Void
    public let onJoinRoom: (String)->Void
    
    public init(onHandleNewRoom: @escaping () -> Void,
         onJoinRoom: @escaping (String) -> Void) {
        self.onHandleNewRoom = onHandleNewRoom
        self.onJoinRoom = onJoinRoom
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 20) {
            LandingPageWelcome()
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)
                .padding(.horizontal, 20)
            
            RoomJoinContainer(
                onHandleNewRoom: onHandleNewRoom,
                onJoinRoom: onJoinRoom)
                .frame(maxWidth: .infinity)
            Spacer()
        }
    }
}

#Preview {
    LandingPageView(
        onHandleNewRoom: {},
        onJoinRoom: {_ in},
        onNavigateToWaitingRoom: {_ in })
}
