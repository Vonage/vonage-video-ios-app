//
//  Created by Vonage on 15/10/26.
//

import SwiftUI
import Testing
import VERACommonUI

@Suite("Avatar display value transfers")
struct AvatarValueTransferTests {
    @Test("A group snapshot preserves participant identity, name and style across isolation boundaries")
    func groupSnapshotPreservesIdentityAndStyle() async {
        let original = [
            AvatarGroupUser(id: "participant-1", name: "Arthur Dent", textColor: .black),
            AvatarGroupUser(id: "", name: "", textColor: .blue),
            AvatarGroupUser(id: "参加者-3", name: "Zoë 李", textColor: .yellow),
        ]
        let store = AvatarSnapshotStore(original)

        let transferred = await Task.detached { await store.snapshot() }.value

        #expect(transferred.count == original.count)
        for (received, expected) in zip(transferred, original) {
            #expect(received.id == expected.id)
            #expect(received.name == expected.name)
            #expect(received.backgroundColor == expected.name.getParticipantColor())
            #expect(received.textColor == expected.textColor)
        }
    }

    @Test("Transferring a default avatar preserves its generated identity and default text color")
    func defaultAvatarKeepsGeneratedIdentity() async {
        let original = AvatarGroupUser(name: "Ford Prefect")
        let store = AvatarSnapshotStore(original)

        let transferred = await Task.detached { await store.snapshot() }.value

        #expect(!original.id.isEmpty)
        #expect(transferred.id == original.id)
        #expect(transferred.name == "Ford Prefect")
        #expect(transferred.backgroundColor == original.backgroundColor)
        #expect(transferred.textColor == .white)
    }

    @Test("An initials snapshot preserves the supplied name", arguments: ["", "Zoë 李", "  Arthur Dent  "])
    func initialsSnapshotPreservesName(name: String) async {
        let original = ParticipantCircleState(userName: name)
        let store = AvatarSnapshotStore(original)

        let transferred = await Task.detached { await store.snapshot() }.value

        #expect(transferred.userName == name)
    }
}

private actor AvatarSnapshotStore<Value: Sendable> {
    private let value: Value

    init(_ value: Value) {
        self.value = value
    }

    func snapshot() -> Value {
        value
    }
}
