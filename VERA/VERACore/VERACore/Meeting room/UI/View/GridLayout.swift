//
//  Created by Vonage on 6/8/25.
//

import SwiftUI

struct GridLayout: View {

    let participants: [Participant]

    let columns = [
        GridItem(.adaptive(minimum: 300), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                GridRow {
                    ForEach(participants, id: \.id) { participant in
                        ParticipantVideoCard(participant: participant)
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
    GridLayout(participants: [
        .init(
            id: "1",
            name: "Arthur Dent",
            isMicEnabled: true,
            isCameraEnabled: true,
            view: AnyView(EmptyView())),
        .init(
            id: "2",
            name: "Ford Prefect",
            isMicEnabled: true,
            isCameraEnabled: true,
            view: AnyView(EmptyView())),
        .init(
            id: "3",
            name: "Zaphod Beeblebrox",
            isMicEnabled: true,
            isCameraEnabled: true,
            view: AnyView(EmptyView())),
        .init(
            id: "4",
            name: "Trillian",
            isMicEnabled: true,
            isCameraEnabled: true,
            view: AnyView(EmptyView())),
        .init(
            id: "5",
            name: "Marvin",
            isMicEnabled: true,
            isCameraEnabled: true,
            view: AnyView(EmptyView())),
        .init(
            id: "6",
            name: "Slartibartfast",
            isMicEnabled: true,
            isCameraEnabled: true,
            view: AnyView(EmptyView())),
        .init(
            id: "7",
            name: "Eddie",
            isMicEnabled: true,
            isCameraEnabled: true,
            view: AnyView(EmptyView())),
        .init(
            id: "8",
            name: "Humma Kavula",
            isMicEnabled: true,
            isCameraEnabled: true,
            view: AnyView(EmptyView())),
        .init(
            id: "9",
            name: "Fenchurch",
            isMicEnabled: true,
            isCameraEnabled: true,
            view: AnyView(EmptyView())),
    ])
}
