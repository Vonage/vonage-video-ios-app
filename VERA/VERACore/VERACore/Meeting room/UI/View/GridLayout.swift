//
//  Created by Vonage on 6/8/25.
//

import SwiftUI

struct GridLayout: View {

    let participants: [Participant]
    let activeSpeakerId: String?

    let columns = [
        GridItem(.adaptive(minimum: 300), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                GridRow {
                    ForEach(participants, id: \.id) { participant in
                        ParticipantVideoCard(
                            participant: participant,
                            activeSpeakerId: activeSpeakerId
                        )
                        .frame(maxWidth: .infinity, minHeight: 200)
                    }
                }
            }
            .animation(.easeInOut, value: participants)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    GridLayout(
        participants: PreviewData.manyParticipants,
        activeSpeakerId: nil)
}
