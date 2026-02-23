//
//  Created by Vonage on 20/02/2026.
//

import Combine
import Foundation
import Testing
import VERADomain

@testable import VERACaptions

@Suite("DefaultCaptionsRepository Tests")
struct DefaultCaptionsRepositoryTests {

    @Test("Initial emission is an empty array")
    func initialEmission() async throws {
        let sut = DefaultCaptionsRepository()

        let captions = try await firstEmission(from: sut.captionsReceived)

        #expect(captions.isEmpty)
    }

    @Test("updateCaptions emits the provided captions to subscribers")
    func updateCaptionsEmits() async throws {
        let sut = DefaultCaptionsRepository()
        let caption = CaptionItem(
            id: "1", speakerName: "Alice", text: "Hello", isMe: false, timestamp: Date()
        )

        await sut.updateCaptions([caption])

        let captions = try await firstEmission(from: sut.captionsReceived)

        #expect(captions.count == 1)
        #expect(captions.first?.id == "1")
        #expect(captions.first?.speakerName == "Alice")
        #expect(captions.first?.text == "Hello")
    }

    @Test("updateCaptions with empty array clears captions")
    func updateWithEmptyClears() async throws {
        let sut = DefaultCaptionsRepository()
        let caption = CaptionItem(
            id: "1", speakerName: "Alice", text: "Hello"
        )

        await sut.updateCaptions([caption])
        await sut.updateCaptions([])

        let captions = try await firstEmission(from: sut.captionsReceived)

        #expect(captions.isEmpty)
    }

    @Test("Multiple updates emit in order and only latest is available via CurrentValueSubject")
    func multipleUpdatesEmitLatest() async throws {
        let sut = DefaultCaptionsRepository()
        let caption1 = CaptionItem(id: "1", speakerName: "Alice", text: "First")
        let caption2 = CaptionItem(id: "2", speakerName: "Bob", text: "Second")

        await sut.updateCaptions([caption1])
        await sut.updateCaptions([caption1, caption2])

        let captions = try await firstEmission(from: sut.captionsReceived)

        #expect(captions.count == 2)
        #expect(captions[0].id == "1")
        #expect(captions[1].id == "2")
    }

    @Test("EmptyCaptionsObserver never emits values")
    func emptyCaptionsObserverCompletes() async throws {
        let sut = NullCaptionsObserver()

        var received = [[CaptionItem]]()
        let cancellable = sut.captionsReceived.sink { received.append($0) }
        _ = cancellable

        #expect(received.isEmpty)
    }

    // MARK: - Helpers

    private func firstEmission(
        from publisher: AnyPublisher<[CaptionItem], Never>
    ) async throws -> [CaptionItem] {
        var result: [CaptionItem] = []
        let cancellable = publisher.sink { result = $0 }
        _ = cancellable
        return result
    }
}
