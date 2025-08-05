//
//  Created by Vonage on 5/8/25.
//

import Foundation
import VERACore

public final class MockArchivesDataSource: ArchivesDataSource {
    public var archivesToReturn: [Archive] = []
    public var responses: [[Archive]] = []
    public var shouldThrowError = false
    public var callCount = 0

    public init(
        archivesToReturn: [Archive] = [],
        responses: [[Archive]] = [],
        shouldThrowError: Bool = false,
        callCount: Int = 0
    ) {
        self.archivesToReturn = archivesToReturn
        self.responses = responses
        self.shouldThrowError = shouldThrowError
        self.callCount = callCount
    }

    public func getArchives(roomName: VERACore.RoomName) async throws -> [VERACore.Archive] {
        callCount += 1

        if shouldThrowError {
            throw MockArchivesDataSourceError()
        }

        if !responses.isEmpty {
            let responseIndex = min(callCount - 1, responses.count - 1)
            return responses[responseIndex]
        }

        return archivesToReturn
    }
}

public struct MockArchivesDataSourceError: Error {}

public func makeMockArchivesDataSource() -> MockArchivesDataSource {
    MockArchivesDataSource()
}
