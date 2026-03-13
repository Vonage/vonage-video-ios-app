//
//  Created by Vonage on 12/3/26.
//

import Foundation
import OSLog
import VERADomain

public final class NoiseSuppressionViewModel: ObservableObject {

    @Published public var state: NoiseSuppressionState = .disabled

    private let logger = Logger(
        subsystem: "com.vonage.VERAAudioEffects",
        category: "NoiseSuppressionButtonViewModel")

    private final let getCurrentPublisher: GetPublisher
    private final let disableNoiseSuppressionUseCase: DisableNoiseSuppressionUseCase
    private final let enableNoiseSuppressionUseCase: EnableNoiseSuppressionUseCase

    public init(
        getCurrentPublisher: @escaping GetPublisher,
        disableNoiseSuppressionUseCase: DisableNoiseSuppressionUseCase,
        enableNoiseSuppressionUseCase: EnableNoiseSuppressionUseCase
    ) {
        self.getCurrentPublisher = getCurrentPublisher
        self.disableNoiseSuppressionUseCase = disableNoiseSuppressionUseCase
        self.enableNoiseSuppressionUseCase = enableNoiseSuppressionUseCase
    }

    public func onTap() {
        state = state.isEnabled ? .disabled : .enabled

        do {
            let publisher = try getCurrentPublisher()

            if state.isEnabled {
                enableNoiseSuppressionUseCase(publisher: publisher)
            } else {
                disableNoiseSuppressionUseCase(publisher: publisher)
            }
        } catch {
            logger.error("\(error.localizedDescription)")
        }
    }
}
