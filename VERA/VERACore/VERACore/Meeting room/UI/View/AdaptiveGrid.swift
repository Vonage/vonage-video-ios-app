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
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                GridRow {
                    ForEach(participants, id: \.id) { participant in
                        ParticipantVideoCard(participant: participant)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AdaptiveGrid(participants: [
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
