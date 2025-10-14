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

public protocol OpenTokPluginRegistrationEvents {
    func registered()
    func unregistered()
}

public protocol OpenTokPluginCallLifeCycle {
    func callDidStart()
    func callDidEnd()
}

public typealias OpenTokPlugin = OpenTokSignalHandler & OpenTokSignalEmmiter & OpenTokPluginRegistrationEvents
    & OpenTokPluginCallLifeCycle & Identifiable
