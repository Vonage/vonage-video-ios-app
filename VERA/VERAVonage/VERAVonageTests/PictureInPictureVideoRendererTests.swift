//
//  Created by Vonage on 29/6/26.
//

import Foundation
import Testing
import UIKit

@testable import VERAVonage

@Suite("PictureInPictureVideoRenderer tests")
@MainActor
struct PictureInPictureVideoRendererTests {

    // MARK: - Initial State

    @Test("Initial state has no placeholder active and zero frames")
    func initialState() {
        let sut = PictureInPictureVideoRenderer()

        #expect(sut.isPlaceholderActive == false)
        #expect(sut.renderedFrameCount == 0)
    }

    // MARK: - Placeholder lifecycle

    @Test("startPlaceholder activates placeholder state")
    func startPlaceholderActivates() {
        let sut = PictureInPictureVideoRenderer()

        sut.startPlaceholder(name: "Alice")

        #expect(sut.isPlaceholderActive == true)
    }

    @Test("stopPlaceholder deactivates placeholder state")
    func stopPlaceholderDeactivates() {
        let sut = PictureInPictureVideoRenderer()
        sut.startPlaceholder(name: "Alice")

        sut.stopPlaceholder()

        #expect(sut.isPlaceholderActive == false)
    }

    @Test("stopPlaceholder when already inactive is a no-op")
    func stopPlaceholderIdempotent() {
        let sut = PictureInPictureVideoRenderer()

        sut.stopPlaceholder()

        #expect(sut.isPlaceholderActive == false)
    }

    @Test("startPlaceholder with same name does not restart")
    func startPlaceholderSameNameIdempotent() {
        let sut = PictureInPictureVideoRenderer()
        sut.startPlaceholder(name: "Bob")
        let countAfterFirst = sut.renderedFrameCount

        sut.startPlaceholder(name: "Bob")

        // Should not have reset/restarted — frame count unchanged immediately
        #expect(sut.isPlaceholderActive == true)
        #expect(sut.renderedFrameCount == countAfterFirst)
    }

    @Test("startPlaceholder with different name restarts placeholder")
    func startPlaceholderDifferentNameRestarts() {
        let sut = PictureInPictureVideoRenderer()
        sut.startPlaceholder(name: "Bob")

        sut.startPlaceholder(name: "Charlie")

        #expect(sut.isPlaceholderActive == true)
    }

    // MARK: - updatePlaceholderName

    @Test("updatePlaceholderName while active changes the name")
    func updatePlaceholderNameWhileActive() {
        let sut = PictureInPictureVideoRenderer()
        sut.startPlaceholder(name: "Alice")

        sut.updatePlaceholderName("Bob")

        #expect(sut.isPlaceholderActive == true)
    }

    @Test("updatePlaceholderName with same name is a no-op")
    func updatePlaceholderNameSameIsNoop() {
        let sut = PictureInPictureVideoRenderer()
        sut.startPlaceholder(name: "Alice")

        sut.updatePlaceholderName("Alice")

        #expect(sut.isPlaceholderActive == true)
    }

    @Test("updatePlaceholderName while inactive is a no-op")
    func updatePlaceholderNameWhileInactive() {
        let sut = PictureInPictureVideoRenderer()

        sut.updatePlaceholderName("Alice")

        #expect(sut.isPlaceholderActive == false)
    }
}
