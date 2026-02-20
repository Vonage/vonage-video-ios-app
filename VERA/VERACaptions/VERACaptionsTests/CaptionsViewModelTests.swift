//
//  Created by Vonage on 20/02/2026.
//

import Combine
import Testing
@testable import VERACaptions
import VERADomain
import Foundation

@Suite("CaptionsViewModel Tests")
@MainActor
struct CaptionsViewModelTests {

    // MARK: - Initial State

    @Test("Initial captions array is empty")
    func initialState() {
        let (sut, _) = makeSUT()

        #expect(sut.captions.isEmpty)
    }

    // MARK: - Receiving Captions

    @Test("Receives a single caption and maps to UICaptionItem")
    func receivesSingleCaption() async throws {
        let (sut, observer) = makeSUT()
        sut.initObservers()

        let caption = CaptionItem(speakerName: "Alice", text: "Hello!")
        observer.send([caption])

        try await waitUntil { sut.captions.count == 1 }

        #expect(sut.captions[0].id == caption.id)
        #expect(sut.captions[0].text == "Alice: Hello!")
        #expect(sut.captions[0].accessibilityLabel == "Alice says: Hello!")
    }

    @Test("Receives multiple captions sorted by most recent first")
    func receivesMultipleCaptionsSortedByTimestamp() async throws {
        let (sut, observer) = makeSUT()
        sut.initObservers()

        let oldest = CaptionItem(speakerName: "Alice", text: "First", timestamp: Date().addingTimeInterval(-3))
        let middle = CaptionItem(speakerName: "Bob", text: "Second", timestamp: Date().addingTimeInterval(-2))
        let newest = CaptionItem(speakerName: "Charlie", text: "Third", timestamp: Date().addingTimeInterval(-1))

        observer.send([middle, oldest, newest])

        try await waitUntil { sut.captions.count == 3 }

        #expect(sut.captions[0].id == newest.id)
        #expect(sut.captions[1].id == middle.id)
        #expect(sut.captions[2].id == oldest.id)
    }

    // MARK: - Max Visible Captions

    @Test("Limits visible captions to 3")
    func limitsToMaxVisibleCaptions() async throws {
        let (sut, observer) = makeSUT()
        sut.initObservers()

        let captions = (0..<5).map { index in
            CaptionItem(
                speakerName: "Speaker\(index)",
                text: "Message \(index)",
                timestamp: Date().addingTimeInterval(TimeInterval(-5 + index))
            )
        }

        observer.send(captions)

        try await waitUntil { sut.captions.count == 3 }

        #expect(sut.captions.count == 3)
        // Should keep the 3 most recent (indices 4, 3, 2)
        #expect(sut.captions[0].id == captions[4].id)
        #expect(sut.captions[1].id == captions[3].id)
        #expect(sut.captions[2].id == captions[2].id)
    }

    @Test("Exactly 3 captions are all shown")
    func exactlyThreeCaptionsAllShown() async throws {
        let (sut, observer) = makeSUT()
        sut.initObservers()

        let captions = (0..<3).map { index in
            CaptionItem(
                speakerName: "Speaker\(index)",
                text: "Message \(index)",
                timestamp: Date().addingTimeInterval(TimeInterval(-3 + index))
            )
        }

        observer.send(captions)

        try await waitUntil { sut.captions.count == 3 }

        #expect(sut.captions.count == 3)
    }

    // MARK: - Updates

    @Test("Updates captions when new data arrives")
    func updatesCaptionsOnNewEmission() async throws {
        let (sut, observer) = makeSUT()
        sut.initObservers()

        let first = [CaptionItem(speakerName: "Alice", text: "Hello")]
        observer.send(first)

        try await waitUntil { sut.captions.count == 1 }
        #expect(sut.captions[0].text == "Alice: Hello")

        let second = [
            CaptionItem(speakerName: "Alice", text: "Hello"),
            CaptionItem(speakerName: "Bob", text: "Hi there"),
        ]
        observer.send(second)

        try await waitUntil { sut.captions.count == 2 }
        #expect(sut.captions.count == 2)
    }

    @Test("Clears captions when empty array is received")
    func clearsCaptionsOnEmptyEmission() async throws {
        let (sut, observer) = makeSUT()
        sut.initObservers()

        observer.send([CaptionItem(speakerName: "Alice", text: "Hello")])
        try await waitUntil { sut.captions.count == 1 }

        observer.send([])
        try await waitUntil { sut.captions.isEmpty }

        #expect(sut.captions.isEmpty)
    }

    // MARK: - UICaptionItem Mapping

    @Test("Maps CaptionItem text format correctly")
    func mapsTextFormat() async throws {
        let (sut, observer) = makeSUT()
        sut.initObservers()

        let caption = CaptionItem(speakerName: "Diana", text: "Let's get started!")
        observer.send([caption])

        try await waitUntil { sut.captions.count == 1 }

        #expect(sut.captions[0].text == "Diana: Let's get started!")
        #expect(sut.captions[0].accessibilityLabel == "Diana says: Let's get started!")
        #expect(sut.captions[0].id == caption.id)
        #expect(sut.captions[0].timestamp == caption.timestamp)
    }

    // MARK: - Observer Lifecycle

    @Test("Does not receive captions before initObservers is called")
    func doesNotReceiveBeforeInit() async throws {
        let (sut, observer) = makeSUT()

        observer.send([CaptionItem(speakerName: "Alice", text: "Hello")])

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.captions.isEmpty)
    }

    // MARK: - Cancel Observers

    @Test("cancelObservers stops receiving new captions")
    func cancelObserversStopsReceiving() async throws {
        let (sut, observer) = makeSUT()
        sut.initObservers()

        observer.send([CaptionItem(speakerName: "Alice", text: "Hello")])
        try await waitUntil { sut.captions.count == 1 }

        sut.cancelObservers()

        observer.send([
            CaptionItem(speakerName: "Alice", text: "Hello"),
            CaptionItem(speakerName: "Bob", text: "New message"),
        ])

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.captions.count == 1)
        #expect(sut.captions[0].text == "Alice: Hello")
    }

    @Test("cancelObservers preserves existing captions")
    func cancelObserversPreservesExistingCaptions() async throws {
        let (sut, observer) = makeSUT()
        sut.initObservers()

        observer.send([CaptionItem(speakerName: "Alice", text: "Hello")])
        try await waitUntil { sut.captions.count == 1 }

        sut.cancelObservers()

        #expect(sut.captions.count == 1)
        #expect(sut.captions[0].text == "Alice: Hello")
    }

    @Test("Can re-subscribe after cancelObservers by calling initObservers again")
    func resubscribeAfterCancel() async throws {
        let (sut, observer) = makeSUT()
        sut.initObservers()

        observer.send([CaptionItem(speakerName: "Alice", text: "Hello")])
        try await waitUntil { sut.captions.count == 1 }

        sut.cancelObservers()

        observer.send([CaptionItem(speakerName: "Bob", text: "Ignored")])
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(sut.captions.count == 1)

        sut.initObservers()

        observer.send([CaptionItem(speakerName: "Charlie", text: "Back online")])
        try await waitUntil { sut.captions.count == 1 && sut.captions[0].text == "Charlie: Back online" }

        #expect(sut.captions[0].text == "Charlie: Back online")
        #expect(sut.captions.count == 1)
    }

    // MARK: - Convenience Init

    @Test("Convenience init creates view model with empty observer")
    func convenienceInit() {
        let sut = CaptionsViewModel()
        sut.initObservers()

        #expect(sut.captions.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT() -> (CaptionsViewModel, MockCaptionsObserver) {
        let observer = MockCaptionsObserver()
        let viewModel = CaptionsViewModel(captionsObserver: observer)
        return (viewModel, observer)
    }

    private func waitUntil(
        timeout: TimeInterval = 0.5,
        _ condition: @escaping @Sendable () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                throw WaitTimeoutError()
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

// MARK: - Test Doubles

private final class MockCaptionsObserver: CaptionsObserver, @unchecked Sendable {
    private let subject = CurrentValueSubject<[CaptionItem], Never>([])

    var captionsReceived: AnyPublisher<[CaptionItem], Never> {
        subject.eraseToAnyPublisher()
    }

    func send(_ captions: [CaptionItem]) {
        subject.send(captions)
    }
}

private struct WaitTimeoutError: Error {}
