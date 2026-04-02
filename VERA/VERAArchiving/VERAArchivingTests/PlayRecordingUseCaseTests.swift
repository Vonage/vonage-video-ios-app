//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERAArchiving
import VERADomain

@Suite("PlayRecordingUseCase tests")
struct PlayRecordingUseCaseTests {

    @Test("PlayRecordingUseCase calls onPlay with recording URL")
    func callsOnPlayWithURL() async throws {
        let expectedURL = URL(string: "https://example.com/recording.mp4")!
        var receivedRecording: ArchiveRecording?

        let sut = DefaultPlayRecordingUseCase(onPlay: { recording in
            receivedRecording = recording
        })

        let archive = Archive(
            id: UUID(),
            name: "Test Archive",
            createdAt: Date(),
            status: .available,
            url: expectedURL,
            size: 1024,
            duration: 60)

        try await sut(archive)

        #expect(receivedRecording?.url == expectedURL)
    }

    @Test("PlayRecordingUseCase throws missingURL when archive has no URL")
    func throwsMissingURLForNilURL() async {
        let sut = DefaultPlayRecordingUseCase(onPlay: { _ in })

        let archive = Archive(
            id: UUID(),
            name: "No URL Archive",
            createdAt: Date(),
            status: .stopped,
            url: nil,
            size: 0,
            duration: 0)

        do {
            try await sut(archive)
            Issue.record("Expected missingURL error")
        } catch let error as DefaultPlayRecordingUseCase.Error {
            #expect(error == .missingURL)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("PlayRecordingUseCase does not call onPlay when URL is missing")
    func doesNotCallOnPlayWhenURLMissing() async {
        var onPlayCalled = false

        let sut = DefaultPlayRecordingUseCase(onPlay: { _ in
            onPlayCalled = true
        })

        let archive = Archive(
            id: UUID(),
            name: "Test",
            createdAt: Date(),
            status: .stopped,
            url: nil,
            size: 0,
            duration: 0)

        try? await sut(archive)

        #expect(onPlayCalled == false)
    }
}
