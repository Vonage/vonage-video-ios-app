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

public protocol OpenTokSignalEmmiter: AnyObject {
    var channel: OpenTokSignalChannel? { get set }
}

/// App based life cycle, plugin registered should be called when app starts
public protocol OpenTokPluginRegistrationEvents {
    func registered()
    func unregistered()
}

/// Call based life cycle, didStart/didEnd are called when app connects/disconnects
public protocol OpenTokPluginCallLifeCycle {
    func callDidStart(_ userInfo: [String: Any])
    func callDidEnd()
}

public typealias OpenTokPlugin = OpenTokSignalHandler & OpenTokSignalEmmiter & OpenTokPluginRegistrationEvents
    & OpenTokPluginCallLifeCycle & Identifiable
