import SwiftUI
import Testing

@testable import VERACore

@MainActor
@Suite("ViewHolder lazy UI construction")
struct ViewHolderOwnershipTests {
    @Test("Transferring the builder preserves lazy UI-owned construction")
    func lazyConstructionAfterTransfer() async {
        let state = ConstructionState()
        let builder = ViewHolder(id: "waiting-room") {
            state.build()
        }

        #expect(state.count == 0)
        let transferred = await Task.detached { builder }.value
        #expect(transferred.id == "waiting-room")
        #expect(state.count == 0)

        _ = transferred.content()
        #expect(state.count == 1)
        _ = transferred.content()
        #expect(state.count == 2)
    }

    @MainActor
    private final class ConstructionState {
        var count = 0

        func build() -> Text {
            MainActor.preconditionIsolated()
            count += 1
            return Text("Build \(count)")
        }
    }
}
