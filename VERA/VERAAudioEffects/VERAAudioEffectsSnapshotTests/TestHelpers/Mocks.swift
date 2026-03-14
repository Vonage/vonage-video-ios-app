//
//  Created by Vonage on 13/03/2026.
//

import VERAAudioEffects
import VERADomain

final class EnableUseCaseSpy: EnableNoiseSuppressionUseCase {
    func callAsFunction(publisher: VERAPublisher) {}
}

final class DisableUseCaseSpy: DisableNoiseSuppressionUseCase {
    func callAsFunction(publisher: VERAPublisher) {}
}
