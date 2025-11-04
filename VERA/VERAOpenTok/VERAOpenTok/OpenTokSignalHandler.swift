//
//  Created by Vonage on 13/10/25.
//

import Foundation

public protocol OpenTokSignalHandler {
    func handleSignal(_ signal: OpenTokSignal)
}

public protocol OpenTokSignalChannel {
    func emitSignal(_ signal: OutgoingSignal) throws
}

public protocol OpenTokSignalEmitter: AnyObject {
    var channel: OpenTokSignalChannel? { get set }
}

/// Call based life cycle, didStart/didEnd are called when app connects/disconnects
public protocol OpenTokPluginCallLifeCycle {
    func callDidStart(_ userInfo: [String: Any])
    func callDidEnd()
}

public typealias OpenTokPlugin = OpenTokSignalHandler & OpenTokSignalEmitter & OpenTokPluginCallLifeCycle & Identifiable
