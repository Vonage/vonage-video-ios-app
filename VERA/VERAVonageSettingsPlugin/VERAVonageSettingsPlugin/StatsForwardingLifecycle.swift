//
//  Created by Vonage on 12/10/2026.
//

import Combine
import VERADomain
import VERASettings

/// Orders statistics source replacement and cleanup without changing plugin protocols.
/// An awaited writer may ignore cancellation: it must finish before the final clear.
actor StatsForwardingLifecycle {
    private let writer: StatsWriter
    private var forwardingTask: Task<Void, Never>?
    private var lifecycleTask: Task<Void, Never>?

    init(writer: StatsWriter) {
        self.writer = writer
    }

    deinit {
        forwardingTask?.cancel()
    }

    /// Returns a handle after submitting the operation, so later requests queue behind it.
    func start(_ publisher: AnyPublisher<NetworkMediaStats, Never>) -> Task<Void, Never> {
        let predecessor = lifecycleTask
        let operation = Task {
            await predecessor?.value
            if forwardingTask != nil {
                await finishForwarding()
            }
            // Capture only the writer/source: an idle stream must not retain this owner.
            forwardingTask = Task.detached { [writer] in
                for await stats in publisher.values {
                    guard !Task.isCancelled else { return }
                    await writer.updateStats(stats)
                }
            }
        }
        lifecycleTask = operation
        return operation
    }

    func stop() -> Task<Void, Never> {
        let predecessor = lifecycleTask
        let operation = Task {
            await predecessor?.value
            await finishForwarding()
        }
        lifecycleTask = operation
        return operation
    }

    private func finishForwarding() async {
        forwardingTask?.cancel()
        await forwardingTask?.value
        forwardingTask = nil
        await writer.clearStats()
    }
}
