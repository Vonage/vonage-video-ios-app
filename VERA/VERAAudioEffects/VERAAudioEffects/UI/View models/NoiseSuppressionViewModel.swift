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
    private final let disableNoiseSuppresionUseCase: DisableNoiseSuppresionUseCase
    private final let enableNoiseSuppresionUseCase: EnableNoiseSuppresionUseCase

    public init(
        getCurrentPublisher: @escaping GetPublisher,
        disableNoiseSuppresionUseCase: DisableNoiseSuppresionUseCase,
        enableNoiseSuppresionUseCase: EnableNoiseSuppresionUseCase
    ) {
        self.getCurrentPublisher = getCurrentPublisher
        self.disableNoiseSuppresionUseCase = disableNoiseSuppresionUseCase
        self.enableNoiseSuppresionUseCase = enableNoiseSuppresionUseCase
    }

    public func onTap() {
        state = state.isEnabled ? .disabled : .enabled

        do {
            let publisher = try getCurrentPublisher()

            if state.isEnabled {
                enableNoiseSuppresionUseCase(publisher: publisher)
            } else {
                disableNoiseSuppresionUseCase()
            }
        } catch {
            logger.error("\(error.localizedDescription)")
        }
    }
}
