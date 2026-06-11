//
//  Created by Vonage on 09/06/2026.
//

import Testing
import VERADomain
import VERAVonage

@testable import VERAE2E

@Suite("E2E call plugin notifier tests")
struct E2ECallPluginNotifierTests {

    @Test("Notifier assigns and unassigns call holders")
    func notifierAssignsAndUnassignsCallHolders() {
        let plugin = PluginSpy()
        let call = E2ECallFacade()
        let sut = E2ECallPluginNotifier(
            plugins: [plugin],
            callParams: [:])

        sut.assign(call: call)
        #expect(plugin.call === call)

        sut.unassign()
        #expect(plugin.call == nil)
    }

    @Test("Notifier sends lifecycle events with params")
    func notifierSendsLifecycleEventsWithParams() async {
        let plugin = PluginSpy()
        let sut = E2ECallPluginNotifier(
            plugins: [plugin],
            callParams: ["roomName": "testroom"])

        await sut.notifyCallDidStart()
        await sut.notifyCallDidEnd()

        #expect(plugin.startParams?["roomName"] as? String == "testroom")
        #expect(plugin.didEnd)
    }
}

private final class PluginSpy: VonagePlugin, VonagePluginCallHolder {
    let pluginIdentifier = "plugin-spy"
    var call: CallFacade?
    private(set) var startParams: [String: Any]?
    private(set) var didEnd = false

    func callDidStart(_ userInfo: [String: Any]) async throws {
        startParams = userInfo
    }

    func callDidEnd() async throws {
        didEnd = true
    }
}
