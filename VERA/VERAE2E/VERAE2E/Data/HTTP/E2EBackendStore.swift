//
//  Created by Vonage on 7/6/26.
//

import Foundation

public actor E2EBackendStore {
    public static let shared = E2EBackendStore()

    private let scenario: any E2ETestScenario
    private var sessionsByKey: [String: E2ESession] = [:]
    private var sessionKeyByRoomName: [String: String] = [:]
    private var archivesBySessionKey: [String: [E2EArchive]] = [:]

    public init(scenario: any E2ETestScenario = E2EConfiguration.scenario) {
        self.scenario = scenario
    }

    func response(for endpoint: E2EEndpoint, requestBody: Data?) async throws -> Data {
        switch endpoint {
        case .createSession:
            return try createSession(requestBody: requestBody)
        case .joinSession:
            return try joinSession(requestBody: requestBody)
        case .startArchive:
            return try startArchive(requestBody: requestBody)
        case .stopArchive:
            return try stopArchive(requestBody: requestBody)
        case .searchArchives:
            return try searchArchives(requestBody: requestBody)
        case .ensureCaptionsEnabled:
            return ensureCaptionsEnabled()
        }
    }

    private func createSession(requestBody: Data?) throws -> Data {
        let body = try E2EHTTPRequestBodyDecoder.decode(requestBody)
        let roomName = body["roomName"] as? String ?? "testroom"

        if let sessionKey = sessionKeyByRoomName[roomName],
            let session = sessionsByKey[sessionKey]
        {
            return E2EHTTPResponseBuilder.envelope([
                "sessionId": session.sessionId,
                "sessionKey": session.sessionKey,
                "applicationId": session.applicationId,
            ])
        }

        let session = E2ESession(
            roomName: roomName,
            sessionId: "e2e-session-\(E2EIdentifier.stableIdentifier(from: roomName))",
            sessionKey: "e2e-session-key-\(UUID().uuidString.lowercased())",
            applicationId: "e2e-application-id"
        )
        sessionsByKey[session.sessionKey] = session
        sessionKeyByRoomName[roomName] = session.sessionKey

        return E2EHTTPResponseBuilder.envelope([
            "sessionId": session.sessionId,
            "sessionKey": session.sessionKey,
            "applicationId": session.applicationId,
        ])
    }

    private func joinSession(requestBody: Data?) throws -> Data {
        let body = try E2EHTTPRequestBodyDecoder.decode(requestBody)
        let sessionKey = body["sessionKey"] as? String ?? ""
        let session = sessionsByKey[sessionKey] ?? fallbackSession(sessionKey: sessionKey)
        sessionsByKey[session.sessionKey] = session

        return E2EHTTPResponseBuilder.envelope([
            "token": "e2e-token-\(UUID().uuidString.lowercased())",
            "applicationId": session.applicationId,
        ])
    }

    private func startArchive(requestBody: Data?) throws -> Data {
        let sessionKey = try sessionKey(from: requestBody)
        let archive = E2EArchive(
            id: UUID().uuidString.lowercased(),
            name: "E2E archive",
            sessionKey: sessionKey,
            status: "started",
            createdAt: Date().timeIntervalSince1970,
            url: nil
        )

        archivesBySessionKey[sessionKey, default: []].append(archive)

        return E2EHTTPResponseBuilder.envelope([
            "id": archive.id,
            "status": archive.status,
        ])
    }

    private func stopArchive(requestBody: Data?) throws -> Data {
        let body = try E2EHTTPRequestBodyDecoder.decode(requestBody)
        let sessionKey = body["sessionKey"] as? String ?? ""
        let archiveId = body["archiveId"] as? String ?? ""
        var archives = archivesBySessionKey[sessionKey] ?? []

        if let index = archives.firstIndex(where: { $0.id == archiveId }) {
            archives[index].status = "available"
            archives[index].url = "https://example.com/e2e/archive-\(archiveId).mp4"
        } else {
            archives.append(
                E2EArchive(
                    id: archiveId.isEmpty ? UUID().uuidString.lowercased() : archiveId,
                    name: "E2E archive",
                    sessionKey: sessionKey,
                    status: "available",
                    createdAt: Date().timeIntervalSince1970,
                    url: "https://example.com/e2e/archive-\(archiveId).mp4"
                ))
        }

        archivesBySessionKey[sessionKey] = archives

        return E2EHTTPResponseBuilder.envelope([
            "id": archives.last?.id ?? archiveId,
            "status": "available",
        ])
    }

    private func searchArchives(requestBody: Data?) throws -> Data {
        let sessionKey = try sessionKey(from: requestBody)
        let archives = downloadableArchives(for: sessionKey)
        archivesBySessionKey[sessionKey] = archives

        return E2EHTTPResponseBuilder.envelope([
            "items": archives.map(remoteArchive),
            "count": archives.count,
        ])
    }

    private func ensureCaptionsEnabled() -> Data {
        let captionsId =
            captionsFixtureMode == .deterministic
            ? "e2e-captions-deterministic"
            : "e2e-captions-\(UUID().uuidString.lowercased())"

        return E2EHTTPResponseBuilder.envelope([
            "captionsId": captionsId
        ])
    }

    private var captionsFixtureMode: E2EFixtureMode? {
        (scenario.fixture as? any E2ECaptionsScenarioFixture)?.mode
    }

    private func downloadableArchives(for sessionKey: String) -> [E2EArchive] {
        let archives = archivesBySessionKey[sessionKey] ?? []
        let availableArchives = archives.map { archive in
            var archive = archive
            archive.status = "available"
            archive.url = archive.url ?? "https://example.com/e2e/archive-\(archive.id).mp4"
            return archive
        }

        if !availableArchives.isEmpty {
            return availableArchives
        }

        return [
            E2EArchive(
                id: UUID().uuidString.lowercased(),
                name: "E2E archive",
                sessionKey: sessionKey,
                status: "available",
                createdAt: Date().timeIntervalSince1970,
                url: "https://example.com/e2e/archive.mp4"
            )
        ]
    }

    private func remoteArchive(_ archive: E2EArchive) -> [String: Any] {
        let session = sessionsByKey[archive.sessionKey] ?? fallbackSession(sessionKey: archive.sessionKey)

        return [
            "id": archive.id,
            "status": archive.status,
            "name": archive.name,
            "reason": NSNull(),
            "sessionId": session.sessionId,
            "applicationId": session.applicationId,
            "createdAt": archive.createdAt,
            "size": 1_024_000,
            "duration": 10,
            "outputMode": "composed",
            "streamMode": "auto",
            "hasAudio": true,
            "hasVideo": true,
            "hasTranscription": false,
            "sha256sum": "e2e-sha256",
            "password": "",
            "updatedAt": Date().timeIntervalSince1970,
            "multiArchiveTag": "",
            "event": "archive",
            "resolution": "640x480",
            "url": archive.url as Any,
        ]
    }

    private func sessionKey(from requestBody: Data?) throws -> String {
        let body = try E2EHTTPRequestBodyDecoder.decode(requestBody)
        return body["sessionKey"] as? String ?? "e2e-session-key"
    }

    private func fallbackSession(sessionKey: String) -> E2ESession {
        E2ESession(
            roomName: "testroom",
            sessionId: "e2e-session-\(E2EIdentifier.stableIdentifier(from: sessionKey))",
            sessionKey: sessionKey.isEmpty ? "e2e-session-key" : sessionKey,
            applicationId: "e2e-application-id"
        )
    }
}
