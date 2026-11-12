//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERAVonage

@Suite("Signal snapshot value transfer")
struct SignalValueTransferTests {

    @Test("Incoming signal fields preserve absent, empty, and Unicode values across tasks and actors")
    func incomingSignalsAcrossTasksAndActor() async {
        let signals = [
            VonageSignal(type: "", data: nil),
            VonageSignal(type: "signal.empty", data: "", connectionId: ""),
            VonageSignal(type: "chat.message", data: "synthetic message", connectionId: "synthetic-connection"),
            VonageSignal(type: "signal.東京-🎥", data: "réunion-👩🏽‍💻", connectionId: "participant-東京"),
        ]
        let transferred = await Task.detached { signals }.value
        let storage = SignalValueStorage()
        await storage.storeIncoming(transferred)
        let received = await storage.incoming
        #expect(received.map(\.type) == ["", "signal.empty", "chat.message", "signal.東京-🎥"])
        #expect(received.map(\.data) == [nil, "", "synthetic message", "réunion-👩🏽‍💻"])
        #expect(received.map(\.connectionId) == [nil, "", "synthetic-connection", "participant-東京"])
    }

    @Test("Outgoing signal fields preserve absent, empty, and Unicode payloads across tasks and actors")
    func outgoingSignalsAcrossTasksAndActor() async {
        let signals = [
            OutgoingSignal(type: "", payload: nil),
            OutgoingSignal(type: "signal.empty", payload: ""),
            OutgoingSignal(type: "chat.message", payload: "synthetic message"),
            OutgoingSignal(type: "signal.東京-🎥", payload: "réunion-👩🏽‍💻"),
        ]
        let transferred = await Task.detached { signals }.value
        let storage = SignalValueStorage()
        await storage.storeOutgoing(transferred)
        let received = await storage.outgoing
        #expect(received.map(\.type) == ["", "signal.empty", "chat.message", "signal.東京-🎥"])
        #expect(received.map(\.payload) == [nil, "", "synthetic message", "réunion-👩🏽‍💻"])
    }
}

private actor SignalValueStorage {
    private(set) var incoming: [VonageSignal] = []
    private(set) var outgoing: [OutgoingSignal] = []

    func storeIncoming(_ values: [VonageSignal]) {
        incoming = values
    }

    func storeOutgoing(_ values: [OutgoingSignal]) {
        outgoing = values
    }
}
