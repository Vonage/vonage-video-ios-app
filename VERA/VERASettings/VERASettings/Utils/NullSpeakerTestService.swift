//
//  Created by Vonage on 03/07/26.
//

import VERADomain

/// A no-op implementation of ``SpeakerTestService`` used in previews and
/// environments where audio playback is not available or desired.
public struct NullSpeakerTestService: SpeakerTestService {
    public init() {}
    public func playTestSound() {}
}
