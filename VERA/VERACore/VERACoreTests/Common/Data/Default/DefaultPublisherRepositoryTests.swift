//
//  Created by Vonage on 17/7/25.
//

import Foundation
import SwiftUI
import Testing
import VERACore
import VERATestHelpers
import XCTest

final class DefaultPublisherRepositoryTests: XCTestCase {

    func test_resetPublisher_doesNotLeakPublishers() async throws {
        let publisher = MockVERAPublisher()
        let publisherFactory = MockPublisherFactory(mockPublisher: publisher)
        let sut = try await makeSUT(publisherFactory: publisherFactory)

        _ = try sut.getPublisher()

        sut.resetPublisher()
    }

    // MARK: - Test Helpers

    private func makeSUT(
        publisherFactory: MockPublisherFactory,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> DefaultPublisherRepository {

        let repository = DefaultPublisherRepository(publisherFactory: publisherFactory)
        let publisher = try repository.getPublisher()

        trackForMemoryLeaks(publisher, file: file, line: line)
        trackForMemoryLeaks(publisherFactory, file: file, line: line)
        trackForMemoryLeaks(repository, file: file, line: line)

        return repository
    }
}
