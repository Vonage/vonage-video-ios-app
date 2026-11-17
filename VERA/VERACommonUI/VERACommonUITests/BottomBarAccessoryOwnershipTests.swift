import SwiftUI
import Testing

@testable import VERACommonUI

@MainActor
@Suite("BottomBarAccessory lazy UI construction")
struct BottomBarAccessoryOwnershipTests {
    @Test("Transferring the builder preserves lazy UI-owned construction")
    func lazyConstructionAfterTransfer() async {
        let state = ConstructionState()
        let builder = BottomBarButtonAccessory(placement: .topTrailing) {
            state.build()
        }

        #expect(state.count == 0)
        let content = builder.content
        let transferred = await Task.detached { content }.value
        #expect(state.count == 0)

        _ = transferred()
        #expect(state.count == 1)
        _ = transferred()
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
