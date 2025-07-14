//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

struct ParticipantCircleState {
    let initials: String
    let color: Color
    let isMicrophoneEnabled: Bool
    let isCameraEnabled: Bool
    
    init(initials: String,
         color: Color,
         isMicrophoneEnabled: Bool,
         isCameraEnabled: Bool) {
        self.initials = initials
        self.color = color
        self.isMicrophoneEnabled = isMicrophoneEnabled
        self.isCameraEnabled = isCameraEnabled
    }
}

struct ParticipantCircleView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    private let state: ParticipantCircleState
    
    init(
        state: ParticipantCircleState
    ) {
        self.state = state
    }
    
    var body: some View {
        VStack(spacing: 0) {

            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let initialsColor = colorScheme == .dark ? Color.black : Color.white
                
                ZStack {
                    Circle()
                        .frame(width: size, height: size)
                        .foregroundColor(state.color)
                    
                    Text(state.initials.uppercased())
                        .font(.system(size: size * 0.5))
                        .foregroundColor(initialsColor)
                        .minimumScaleFactor(0.5)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ParticipantCircleView(
            state: .init(
                initials: "ZB",
                color: .yellow,
                isMicrophoneEnabled: true,
                isCameraEnabled: true)
        )
        .frame(width: 150, height: 200)
        
        ParticipantCircleView(
            state: .init(
                initials: "AB",
                color: .blue,
                isMicrophoneEnabled: false,
                isCameraEnabled: true)
        )
        .frame(width: 150, height: 200)
        
        ParticipantCircleView(
            state: .init(
                initials: "CD",
                color: .green,
                isMicrophoneEnabled: false,
                isCameraEnabled: false)
        )
        .frame(width: 150, height: 200)
    }
    .padding()
    .background(.black)
}
