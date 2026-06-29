//
//  Created by Vonage on 7/6/26.
//

import Testing

@testable import VERAE2E

@Suite("E2E backend store tests")
struct E2EBackendStoreTests {

    @Test("Happy path endpoints return expected tRPC envelopes")
    func happyPathEndpointsReturnExpectedResponses() async throws {
        let sut = E2EHTTPClient(store: E2EBackendStore(), interceptor: HTTPClientInterceptorSpy())

        let createSession = try await postJSON(
            sut,
            endpoint: .createSession,
            body: ["roomName": "testroom"])
        let sessionKey = try #require(createSession["sessionKey"] as? String)
        #expect((createSession["sessionId"] as? String)?.isEmpty == false)
        #expect((createSession["applicationId"] as? String)?.isEmpty == false)

        let joinSession = try await postJSON(
            sut,
            endpoint: .joinSession,
            body: ["sessionKey": sessionKey])
        #expect((joinSession["token"] as? String)?.isEmpty == false)

        let startArchive = try await postJSON(
            sut,
            endpoint: .startArchive,
            body: ["sessionKey": sessionKey])
        let archiveId = try #require(startArchive["id"] as? String)
        #expect(startArchive["status"] as? String == "started")

        let stopArchive = try await postJSON(
            sut,
            endpoint: .stopArchive,
            body: ["sessionKey": sessionKey, "archiveId": archiveId])
        #expect(stopArchive["id"] as? String == archiveId)
        #expect(stopArchive["status"] as? String == "available")

        let captions = try await postJSON(
            sut,
            endpoint: .ensureCaptionsEnabled,
            body: ["sessionKey": sessionKey])
        #expect((captions["captionsId"] as? String)?.isEmpty == false)
    }

    @Test("Search archives returns at least one downloadable archive after stop")
    func searchArchivesReturnsDownloadableArchiveAfterStop() async throws {
        let sut = E2EHTTPClient(store: E2EBackendStore(), interceptor: HTTPClientInterceptorSpy())

        let createSession = try await postJSON(
            sut,
            endpoint: .createSession,
            body: ["roomName": "testroom"])
        let sessionKey = try #require(createSession["sessionKey"] as? String)

        let startArchive = try await postJSON(
            sut,
            endpoint: .startArchive,
            body: ["sessionKey": sessionKey])
        let archiveId = try #require(startArchive["id"] as? String)

        _ = try await postJSON(
            sut,
            endpoint: .stopArchive,
            body: ["sessionKey": sessionKey, "archiveId": archiveId])

        let archivesResponse = try await postJSON(
            sut,
            endpoint: .searchArchives,
            body: ["sessionKey": sessionKey])

        #expect((archivesResponse["count"] as? Int ?? 0) >= 1)
        let items = try #require(archivesResponse["items"] as? [[String: Any]])
        let firstItem = try #require(items.first)
        #expect(firstItem["status"] as? String == "available")
        #expect((firstItem["url"] as? String)?.isEmpty == false)
    }

    @Test("Search archives returns downloadable fallback without prior archive")
    func searchArchivesReturnsDownloadableFallbackWithoutPriorArchive() async throws {
        let sut = E2EHTTPClient(store: E2EBackendStore(), interceptor: HTTPClientInterceptorSpy())

        let archivesResponse = try await postJSON(
            sut,
            endpoint: .searchArchives,
            body: ["sessionKey": "unknown-session-key"])

        #expect((archivesResponse["count"] as? Int ?? 0) >= 1)
        let items = try #require(archivesResponse["items"] as? [[String: Any]])
        let firstItem = try #require(items.first)
        #expect(firstItem["status"] as? String == "available")
        #expect((firstItem["url"] as? String)?.isEmpty == false)
    }

    @Test("Recording scenario keeps deterministic archive lifecycle")
    func recordingScenarioKeepsDeterministicArchiveLifecycle() async throws {
        let sut = E2EHTTPClient(
            store: E2EBackendStore(scenario: E2ETestScenarioRegistry.scenario(named: "recording")),
            interceptor: HTTPClientInterceptorSpy())

        let startArchive = try await postJSON(
            sut,
            endpoint: .startArchive,
            body: ["sessionKey": "recording-session-key"])
        let archiveId = try #require(startArchive["id"] as? String)
        #expect(startArchive["status"] as? String == "started")

        let stopArchive = try await postJSON(
            sut,
            endpoint: .stopArchive,
            body: ["sessionKey": "recording-session-key", "archiveId": archiveId])
        #expect(stopArchive["status"] as? String == "available")

        let archivesResponse = try await postJSON(
            sut,
            endpoint: .searchArchives,
            body: ["sessionKey": "recording-session-key"])
        #expect((archivesResponse["count"] as? Int ?? 0) >= 1)
    }

    @Test("Captions scenario returns a valid captions id")
    func captionsScenarioReturnsValidCaptionsId() async throws {
        let sut = E2EHTTPClient(
            store: E2EBackendStore(scenario: E2ETestScenarioRegistry.scenario(named: "captions")),
            interceptor: HTTPClientInterceptorSpy())

        let captions = try await postJSON(
            sut,
            endpoint: .ensureCaptionsEnabled,
            body: ["sessionKey": "captions-session-key"])

        #expect(captions["captionsId"] as? String == "e2e-captions-deterministic")
    }
}
