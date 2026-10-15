//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERADomain

@Suite("Camera position value transfer")
struct CameraPositionTransferTests {

    @Test("Front and back selections survive task and actor round trips")
    func positionsAcrossTasksAndActor() async {
        let positions: [CameraPosition] = [.front, .back, .front]
        let received = await Task.detached { positions }.value
        #expect(received == positions)

        let selection = CameraSelection()
        for position in received {
            await selection.update(position)
            let selected = await selection.position
            #expect(selected == position)
        }
    }
}

private actor CameraSelection {
    private(set) var position: CameraPosition = .front

    func update(_ value: CameraPosition) {
        position = value
    }
}
