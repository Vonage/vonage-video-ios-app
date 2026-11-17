import SwiftUI
import Testing

@testable import VERAMeetingRoom

@MainActor
@Suite("ViewGenerator lazy UI construction")
struct ViewGeneratorOwnershipTests {
    @Test("Transferring the builder preserves lazy UI-owned construction")
    func lazyConstructionAfterTransfer() async {
        let state = ConstructionState()
        let builder = ViewGenerator(id: "meeting-room") {
            state.build()
        }

        #expect(state.count == 0)
        let transferred = await Task.detached { builder }.value
        #expect(transferred.id == "meeting-room")
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
