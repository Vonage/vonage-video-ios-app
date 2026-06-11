//
//  Created by Vonage on 8/6/26.
//

import VERADomain
import VERAVonage

final class E2ECallPluginNotifier {
    private let plugins: [any VonagePlugin]
    private let callParams: [String: Any]

    init(
        plugins: [any VonagePlugin],
        callParams: [String: Any]
    ) {
        self.plugins = plugins
        self.callParams = callParams
    }

    func assign(call: any CallFacade) {
        plugins.forEach {
            if let callHolder = $0 as? VonagePluginCallHolder {
                callHolder.call = call
            }
        }
    }

    func unassign() {
        plugins.forEach {
            if let callHolder = $0 as? VonagePluginCallHolder {
                callHolder.call = nil
            }
        }
    }

    func notifyCallDidStart() async {
        for plugin in plugins {
            try? await plugin.callDidStart(callParams)
        }
    }

    func notifyCallDidEnd() async {
        for plugin in plugins {
            try? await plugin.callDidEnd()
        }
    }
}
