//
//  Created by Vonage on 20/10/25.
//

import Foundation
import VERAOpenTok

public final class SpyOpenTokSignalChannel: OpenTokSignalChannel {

    public var recordedSignals: [OutgoingSignal]

    public init(recordedSignals: [OutgoingSignal] = []) {
        self.recordedSignals = recordedSignals
    }

    public func emitSignal(_ signal: OutgoingSignal) throws {
        recordedSignals.append(signal)
    }
}
