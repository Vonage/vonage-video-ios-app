//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

struct AdaptiveGrid: View {

    let participants: [Participant]

    let columns = [
        GridItem(.adaptive(minimum: 300), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(participants, id: \.self) { participant in
                    ParticipantVideoCard(participant: participant)
                        .frame(maxWidth: .infinity, minHeight: 200)
                }
            }
            .padding()
        }
    }
}

#Preview {
    AdaptiveGrid(participants: [
        .init(
            id: "1",
            name: "Arthur",
            isMicEnabled: true,
            isCameraEnabled: true,
            view: AnyView(EmptyView()))
    ])
}
