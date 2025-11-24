//
//  Created by Vonage on 13/10/25.
//

import Foundation
import VERACore

public protocol OpenTokSignalHandler {
    func handleSignal(_ signal: OpenTokSignal)
}

public protocol OpenTokSignalChannel: AnyObject {
    func emitSignal(_ signal: OutgoingSignal) throws
}

public protocol OpenTokSignalEmitter: AnyObject {
    var channel: OpenTokSignalChannel? { get set }
}

/// Call based life cycle, didStart/didEnd are called when app connects/disconnects
public protocol OpenTokPluginCallLifeCycle {
    func callDidStart(_ userInfo: [String: Any]) async throws
    func callDidEnd() async throws
}

public protocol OpenTokPluginCallHolder: AnyObject {
    var call: VERACore.CallFacade? { get set }
}

public protocol OpenTokPluginID {
    var pluginIdentifier: String { get }
}

public typealias OpenTokPlugin = OpenTokPluginCallLifeCycle & OpenTokPluginID
