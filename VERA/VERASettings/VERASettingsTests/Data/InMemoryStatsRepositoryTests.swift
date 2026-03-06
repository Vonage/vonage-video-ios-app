//
//  Created by Vonage on 5/3/26.
//

import Combine
import Foundation
import Testing
import VERADomain

@testable import VERASettings

@Suite("InMemoryStatsRepository Tests")
struct InMemoryStatsRepositoryTests {

    // MARK: - Initial State Tests

    @Test("Repository initializes with empty stats")
    func initializesWithEmptyStats() async {
        let repository = InMemoryStatsRepository()

        var receivedStats: NetworkMediaStats?
        let cancellable = repository.statsPublisher
            .sink { stats in
                receivedStats = stats
            }

        await delay()

        #expect(receivedStats == NetworkMediaStats.empty)

        cancellable.cancel()
    }

    @Test("Publisher emits initial empty value immediately")
    func publisherEmitsInitialValue() async throws {
        let repository = InMemoryStatsRepository()

        var receivedStats: NetworkMediaStats?
        let cancellable = repository.statsPublisher
            .sink { stats in
                receivedStats = stats
            }

        // Wait for emission
        await delay()

        #expect(receivedStats == NetworkMediaStats.empty)

        cancellable.cancel()
    }

    // MARK: - Update Stats Tests

    @Test("updateStats updates current value and emits through publisher")
    func updateStatsEmitsThroughPublisher() async throws {
        let repository = InMemoryStatsRepository()

        var emittedValues: [NetworkMediaStats] = []
        let cancellable = repository.statsPublisher
            .sink { stats in
                emittedValues.append(stats)
            }

        // Wait for initial value
        await delay()

        // Update stats
        let testStats = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100,
                packetsLost: 5,
                bytesSent: 10_000,
                timestamp: 1000,
                audioCodec: "opus"
            )
        )
        await repository.updateStats(testStats)

        // Wait for update
        await delay()

        #expect(emittedValues.count == 2)
        #expect(emittedValues[0] == NetworkMediaStats.empty)
        #expect(emittedValues[1] == testStats)
        #expect(emittedValues.last == testStats)

        cancellable.cancel()
    }

    @Test("Multiple subscribers receive the same updates")
    func multipleSubscribersReceiveUpdates() async throws {
        let repository = InMemoryStatsRepository()

        var subscriber1Values: [NetworkMediaStats] = []
        var subscriber2Values: [NetworkMediaStats] = []

        let cancellable1 = repository.statsPublisher
            .sink { stats in
                subscriber1Values.append(stats)
            }

        let cancellable2 = repository.statsPublisher
            .sink { stats in
                subscriber2Values.append(stats)
            }

        // Wait for initial emissions
        await delay()

        // Update stats
        let testStats = NetworkMediaStats(
            sentVideo: VideoSendStats(
                packetsSent: 200,
                packetsLost: 10,
                bytesSent: 50_000,
                timestamp: 2000,
                videoCodec: "VP8"
            )
        )
        await repository.updateStats(testStats)

        // Wait for update
        await delay()

        #expect(subscriber1Values.count == 2)
        #expect(subscriber2Values.count == 2)
        #expect(subscriber1Values[1] == testStats)
        #expect(subscriber2Values[1] == testStats)

        cancellable1.cancel()
        cancellable2.cancel()
    }

    @Test("Multiple updates emit correctly in sequence")
    func multipleUpdatesEmitInSequence() async throws {
        let repository = InMemoryStatsRepository()

        var emittedValues: [NetworkMediaStats] = []
        let cancellable = repository.statsPublisher
            .sink { stats in
                emittedValues.append(stats)
            }

        // Wait for initial value
        await delay()

        // First update
        let stats1 = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100,
                packetsLost: 1,
                bytesSent: 5000,
                timestamp: 1000
            )
        )
        await repository.updateStats(stats1)
        await delay()

        // Second update
        let stats2 = NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 200,
                packetsLost: 2,
                bytesSent: 10_000,
                timestamp: 2000
            )
        )
        await repository.updateStats(stats2)
        await delay()

        #expect(emittedValues.count == 3)
        #expect(emittedValues[0] == NetworkMediaStats.empty)
        #expect(emittedValues[1] == stats1)
        #expect(emittedValues[2] == stats2)

        cancellable.cancel()
    }

    // MARK: - Clear Stats Tests

    @Test("clearStats resets to empty and emits through publisher")
    func clearStatsResetsToEmpty() async throws {
        let repository = InMemoryStatsRepository()

        var emittedValues: [NetworkMediaStats] = []
        let cancellable = repository.statsPublisher
            .sink { stats in
                emittedValues.append(stats)
            }

        // Wait for initial value
        await delay()

        // Update with data
        let testStats = NetworkMediaStats(
            receivedAudio: AudioReceiveStats(
                packetsReceived: 150,
                packetsLost: 3,
                bytesReceived: 7500,
                timestamp: 1500,
                estimatedBandwidth: 128_000
            )
        )
        await repository.updateStats(testStats)
        await delay()

        // Clear stats
        await repository.clearStats()
        await delay()

        #expect(emittedValues.count == 3)
        #expect(emittedValues[0] == NetworkMediaStats.empty)
        #expect(emittedValues[1] == testStats)
        #expect(emittedValues[2] == NetworkMediaStats.empty)
        #expect(emittedValues.last == NetworkMediaStats.empty)

        cancellable.cancel()
    }

    // MARK: - Thread Safety Tests

    @Test("Concurrent updates are handled safely")
    func concurrentUpdatesAreSafe() async throws {
        let repository = InMemoryStatsRepository()

        var emittedValues: [NetworkMediaStats] = []
        let cancellable = repository.statsPublisher
            .sink { stats in
                emittedValues.append(stats)
            }

        // Wait for initial value
        await delay()

        // Perform concurrent updates
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let stats = NetworkMediaStats(
                        sentAudio: AudioSendStats(
                            packetsSent: Int64(clamping: UInt64(i * 100)),
                            packetsLost: Int64(clamping: UInt64(i)),
                            bytesSent: Int64(clamping: UInt64(i * 1000)),
                            timestamp: Double(i)
                        )
                    )
                    await repository.updateStats(stats)
                }
            }
        }

        // Wait for all updates to propagate
        await delay()

        // Should have initial + 10 updates
        #expect(emittedValues.count == 11)
        #expect(emittedValues[0] == NetworkMediaStats.empty)

        // Final state should be one of the updates (actor ensures safe mutations)
        #expect(emittedValues.last != NetworkMediaStats.empty)

        cancellable.cancel()
    }
}
