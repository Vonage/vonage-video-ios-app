//
//  Created by Vonage on 5/8/25.
//

import Foundation
import VERAArchiving
import VERADomain

public final class MockArchivesDataSource: ArchivesDataSource, @unchecked Sendable {
    private let lock = NSLock()
    private var storedArchives: [Archive]
    private var storedResponses: [[Archive]]
    private var storedShouldThrow: Bool
    private var storedCallCount: Int

    public var archivesToReturn: [Archive] {
        get { withLock { storedArchives } }
        set { withLock { storedArchives = newValue } }
    }
    public var responses: [[Archive]] {
        get { withLock { storedResponses } }
        set { withLock { storedResponses = newValue } }
    }
    public var shouldThrowError: Bool {
        get { withLock { storedShouldThrow } }
        set { withLock { storedShouldThrow = newValue } }
    }
    public var callCount: Int {
        get { withLock { storedCallCount } }
        set { withLock { storedCallCount = newValue } }
    }

    public init(
        archivesToReturn: [Archive] = [], responses: [[Archive]] = [],
        shouldThrowError: Bool = false, callCount: Int = 0
    ) {
        storedArchives = archivesToReturn
        storedResponses = responses
        storedShouldThrow = shouldThrowError
        storedCallCount = callCount
    }

    private func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    public func getArchives(sessionKey: String) async throws -> [Archive] {
        try withLock {
            storedCallCount += 1
            if storedShouldThrow { throw MockArchivesDataSourceError() }
            if !storedResponses.isEmpty {
                return storedResponses[min(storedCallCount - 1, storedResponses.count - 1)]
            }
            return storedArchives
        }
    }
}

public struct MockArchivesDataSourceError: Error {}
public func makeMockArchivesDataSource() -> MockArchivesDataSource { MockArchivesDataSource() }
