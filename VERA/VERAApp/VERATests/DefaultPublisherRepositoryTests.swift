//
//  Created by Vonage on 17/7/25.
//

import Foundation
import SwiftUI
import Testing
import VERA
import VERACore
import XCTest

final class DefaultPublisherRepositoryTests: XCTestCase {

    func test_resetPublisher_doesNotLeakPublishers() {
        let publisher = MockVERAPublisher()
        let publisherFactory = MockPublisherFactory(mockPublisher: publisher)
        let sut = makeSUT(publisherFactory: publisherFactory)

        _ = sut.getPublisher()

        sut.resetPublisher()
    }

    // MARK: - Test Helpers

    private func makeSUT(
        publisherFactory: MockPublisherFactory,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> DefaultPublisherRepository {

        let repository = DefaultPublisherRepository(publisherFactory: publisherFactory)
        let publisher = repository.getPublisher()

        trackForMemoryLeaks(publisher, file: file, line: line)
        trackForMemoryLeaks(publisherFactory, file: file, line: line)
        trackForMemoryLeaks(repository, file: file, line: line)

        return repository
    }
}
