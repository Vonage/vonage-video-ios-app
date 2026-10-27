//
//  Created by Vonage on 19/10/26.
//

import Testing
import VERATestHelpers

@testable import VERACore

@MainActor
@Suite("Goodbye UI navigation ownership")
struct GoodByeViewModelTests {
    @Test("Reenter and landing actions invoke their matching UI callback")
    func dispatchesNavigationActions() {
        var actions: [String] = []
        let sut = GoodByeViewModel(
            roomName: "heart-of-gold",
            userRepository: makeMockUserRepository(),
            goodByeNavigation: GoodByeNavigation(
                onReenter: {
                    MainActor.preconditionIsolated()
                    actions.append("reenter")
                },
                onReturnToLanding: {
                    MainActor.preconditionIsolated()
                    actions.append("landing")
                }))

        sut.onReenter()
        #expect(actions == ["reenter"])
        sut.onReturnToLanding()
        #expect(actions == ["reenter", "landing"])
        #expect(sut.roomName == "heart-of-gold")
    }
}
