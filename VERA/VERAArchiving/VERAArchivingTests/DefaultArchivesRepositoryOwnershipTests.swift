import Combine
import Foundation
import Testing
import VERAArchiving
import VERADomain

@MainActor
@Suite("Archive polling ownership")
struct DefaultArchivesRepositoryOwnershipTests {
    @Test("Polling does not retain a released repository between requests")
    func releasesRepositoryWhileWaitingForNextPoll() async throws {
        let archive = Archive(
            id: UUID(),
            name: "Pending",
            createdAt: Date(),
            status: .stopped,
            url: nil,
            size: 0,
            duration: 0)
        let source = PendingArchivesSource(archive: archive)
        var repository: DefaultArchivesRepository? = DefaultArchivesRepository(
            pollingIntervalSeconds: 60, archivesDataSource: source)
        weak var releasedRepository = repository
        let publisher = try #require(await repository?.getArchives(sessionKey: "room"))
        let (stream, subscription) = makeArchivePublisherTestStream(from: publisher)
        defer { subscription.cancel() }
        let first = try await stream.first { @Sendable value in !value.isEmpty }
        #expect(first?.first?.id == archive.id)

        repository = nil

        #expect(releasedRepository == nil)
        #expect(await source.callCount == 1)
    }

    @Test("An in-flight request does not retain the UI repository", .timeLimit(.minutes(1)))
    func releasesRepositoryDuringSuspendedRequest() async throws {
        let source = SuspendedArchivesSource()
        var repository: DefaultArchivesRepository? = DefaultArchivesRepository(
            pollingIntervalSeconds: 60, archivesDataSource: source)
        weak var releasedRepository = repository
        let publisher = try #require(await repository?.getArchives(sessionKey: "room"))
        await source.waitForRequests(1)

        repository = nil

        #expect(releasedRepository == nil)
        // Even a service that ignores cancellation can finish without resurrecting the owner.
        await source.finishRequest(0, archives: [])
        withExtendedLifetime(publisher) {}
    }

    @Test("A cancelled request cannot fail a replacement room subscription", .timeLimit(.minutes(1)))
    func ignoresCancelledRequestFailureAfterRestart() async throws {
        let source = SuspendedArchivesSource()
        let repository = DefaultArchivesRepository(pollingIntervalSeconds: 60, archivesDataSource: source)
        let original = await repository.getArchives(sessionKey: "room")
        await source.waitForRequests(1)
        let replacement = await repository.getArchives(sessionKey: "room")
        await source.waitForRequests(2)

        // This source deliberately ignores cancellation and completes the superseded request.
        await source.failRequest(0)
        let archive = Archive(
            id: UUID(),
            name: "Ready",
            createdAt: Date(),
            status: .available,
            url: nil,
            size: 0,
            duration: 0)
        await source.finishRequest(1, archives: [archive])

        let (replacementStream, replacementSubscription) = makeArchivePublisherTestStream(from: replacement)
        let (originalStream, originalSubscription) = makeArchivePublisherTestStream(from: original)
        defer {
            replacementSubscription.cancel()
            originalSubscription.cancel()
        }
        let current = try await replacementStream.first { @Sendable value in !value.isEmpty }
        let shared = try await originalStream.first { @Sendable value in !value.isEmpty }
        #expect(current?.first?.id == archive.id)
        #expect(shared?.first?.id == archive.id)
        #expect(await source.requestCount == 2)
    }

}

private actor PendingArchivesSource: ArchivesDataSource {
    private let archive: Archive
    private(set) var callCount = 0

    init(archive: Archive) { self.archive = archive }

    func getArchives(sessionKey: String) async throws -> [Archive] {
        callCount += 1
        return [archive]
    }
}

private actor SuspendedArchivesSource: ArchivesDataSource {
    private var requests: [CheckedContinuation<[Archive], Error>?] = []
    private var waiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []
    var requestCount: Int { requests.count }

    func getArchives(sessionKey: String) async throws -> [Archive] {
        try await withCheckedThrowingContinuation { continuation in
            requests.append(continuation)
            let ready = waiters.filter { $0.count <= requests.count }
            waiters.removeAll { $0.count <= requests.count }
            for waiter in ready {
                waiter.continuation.resume()
            }
        }
    }

    func waitForRequests(_ count: Int) async {
        guard requests.count < count else { return }
        await withCheckedContinuation { continuation in
            waiters.append((count, continuation))
        }
    }

    func failRequest(_ index: Int) {
        let continuation = requests[index]
        requests[index] = nil
        continuation?.resume(throwing: URLError(.cancelled))
    }

    func finishRequest(_ index: Int, archives: [Archive]) {
        let continuation = requests[index]
        requests[index] = nil
        continuation?.resume(returning: archives)
    }
}
