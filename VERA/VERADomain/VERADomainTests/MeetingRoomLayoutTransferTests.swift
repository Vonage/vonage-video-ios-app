//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERADomain

@Suite("Meeting layout value transfer")
struct MeetingRoomLayoutTransferTests {

    @Test("Both layouts retain their selection across task and actor boundaries")
    func layoutsAcrossTasksAndActor() async {
        let layouts: [MeetingRoomLayout] = [.activeSpeaker, .grid, .activeSpeaker]
        let received = await Task.detached { layouts }.value
        #expect(received == layouts)

        let selection = LayoutSelection()
        for layout in received {
            await selection.update(layout)
            let selected = await selection.layout
            #expect(selected == layout)
        }
    }
}

private actor LayoutSelection {
    private(set) var layout: MeetingRoomLayout = .activeSpeaker

    func update(_ value: MeetingRoomLayout) {
        layout = value
    }
}
