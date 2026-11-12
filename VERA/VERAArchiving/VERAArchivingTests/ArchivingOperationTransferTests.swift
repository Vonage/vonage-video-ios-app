//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import Testing
import VERAArchiving

@Suite("Archiving operation value transfer")
struct ArchivingOperationTransferTests {
    @Test("Start requests cross tasks and an actor implementing the existing use-case protocol")
    func startRequestsAcrossTasksAndActor() async throws {
        let operations = RecordingOperations()
        let useCase: any StartArchivingUseCase = operations
        let sessionKeys = ["", "room/東京?participant=Zoë"]

        for key in sessionKeys {
            let request = await transfer(StartArchivingRequest(sessionKey: key))
            let archiveID = try await useCase(request)
            #expect(archiveID == "archive/\(key)")
        }
        #expect(await operations.startedSessionKeys == sessionKeys)
    }

    @Test("Stop requests preserve both identifiers through task and actor boundaries")
    func stopRequestsAcrossTasksAndActor() async throws {
        let operations = RecordingOperations()
        let useCase: any StopArchivingUseCase = operations
        let requests = [
            StopArchivingRequest(sessionKey: "", archiveID: ""),
            StopArchivingRequest(sessionKey: "room/東京", archiveID: "recording/Zoë?version=2"),
        ]
        for request in requests {
            try await useCase(await transfer(request))
        }
        let received = await operations.stoppedRequests
        #expect(received.map(\.sessionKey) == requests.map(\.sessionKey))
        #expect(received.map(\.archiveID) == requests.map(\.archiveID))
    }

    @Test("Recording results retain URL queries, fragments and relative bases after transfer")
    func recordingURLsAcrossTasksAndActor() async throws {
        let absolute = try #require(
            URL(string: "https://example.invalid/recordings/meeting%20one.mp4?version=2#preview"))
        let base = try #require(URL(string: "https://example.invalid/recordings/"))
        let relative = try #require(URL(string: "meeting%20two.mp4?version=3#preview", relativeTo: base))
        let storage = RecordingResultStorage()

        for url in [absolute, relative] {
            let recording = await transfer(ArchiveRecording(url: url))
            await storage.update(recording)
            let received = try #require(await storage.recording)
            #expect(received.url == url)
            #expect(received.url.absoluteString == url.absoluteString)
            #expect(received.url.relativeString == url.relativeString)
            #expect(received.url.baseURL == url.baseURL)
        }
    }

    private func transfer<Value: Sendable>(_ value: Value) async -> Value {
        await Task.detached { value }.value
    }
}

private actor RecordingOperations: StartArchivingUseCase, StopArchivingUseCase {
    private(set) var startedSessionKeys: [String] = []
    private(set) var stoppedRequests: [StopArchivingRequest] = []

    func callAsFunction(_ request: StartArchivingRequest) async throws -> ArchiveID {
        startedSessionKeys.append(request.sessionKey)
        return "archive/\(request.sessionKey)"
    }

    func callAsFunction(_ request: StopArchivingRequest) async throws {
        stoppedRequests.append(request)
    }
}

private actor RecordingResultStorage {
    private(set) var recording: ArchiveRecording?

    func update(_ value: ArchiveRecording) {
        recording = value
    }
}
