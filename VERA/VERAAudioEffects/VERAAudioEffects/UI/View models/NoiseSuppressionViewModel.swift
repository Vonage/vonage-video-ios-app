//
//  Created by Vonage on 12/3/26.
//

import Combine
import Foundation
import OSLog
import Observation
import VERADomain

@Observable
public final class NoiseSuppressionViewModel {

    @ObservationIgnored private var statusCancellable: AnyCancellable?

    public var state: NoiseSuppressionState = .disabled

    @ObservationIgnored
    private let logger = Logger(
        subsystem: "com.vonage.VERAAudioEffects",
        category: "NoiseSuppressionButtonViewModel")

    @ObservationIgnored
    private final let getCurrentPublisher: GetPublisher
    @ObservationIgnored
    private final let disableNoiseSuppressionUseCase: DisableNoiseSuppressionUseCase
    @ObservationIgnored
    private final let enableNoiseSuppressionUseCase: EnableNoiseSuppressionUseCase

    public init(
        getCurrentPublisher: @escaping GetPublisher,
        disableNoiseSuppressionUseCase: DisableNoiseSuppressionUseCase,
        enableNoiseSuppressionUseCase: EnableNoiseSuppressionUseCase,
        statusDataSource: NoiseSuppressionStatusDataSource? = nil
    ) {
        self.getCurrentPublisher = getCurrentPublisher
        self.disableNoiseSuppressionUseCase = disableNoiseSuppressionUseCase
        self.enableNoiseSuppressionUseCase = enableNoiseSuppressionUseCase
        if let statusDataSource {
            statusCancellable = statusDataSource.noiseSuppressionState
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in self?.state = state }
        }
    }

    public func onTap() {
        let newState: NoiseSuppressionState = state.isEnabled ? .disabled : .enabled

        updateState(to: newState)
    }

    public func updateState(to state: NoiseSuppressionState) {
        self.state = state

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
