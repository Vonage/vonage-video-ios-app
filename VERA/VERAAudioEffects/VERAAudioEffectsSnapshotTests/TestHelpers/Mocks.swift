//
//  Created by Vonage on 13/03/2026.
//

import VERAAudioEffects
import VERADomain

final class EnableUseCaseSpy: EnableNoiseSuppresionUseCase {
    func callAsFunction(publisher: VERAPublisher) {}
}

final class DisableUseCaseSpy: DisableNoiseSuppresionUseCase {
    func callAsFunction() {}
}
