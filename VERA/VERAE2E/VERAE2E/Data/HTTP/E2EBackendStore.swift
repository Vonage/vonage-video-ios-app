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
        let body = try E2EHTTPRequestBodyDecoder.decode(requestBody)
        let sessionKey = body["sessionKey"] as? String ?? "e2e-session-key"
        let withTranscription = body["withTranscription"] as? Bool ?? false
        let archive = E2EArchive(
            id: UUID().uuidString.lowercased(),
            name: withTranscription ? "transcription" : "E2E archive",
            sessionKey: sessionKey,
            status: "started",
            createdAt: Date().timeIntervalSince1970,
            url: nil,
            transcription: withTranscription ? E2ETranscription() : nil
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
            if var transcription = archive.transcription {
                // The audio archive is done, but its transcript keeps processing for a few polls.
                archive.status = "uploaded"
                archive.url = nil
                if transcription.pendingPolls > 0 {
                    transcription.pendingPolls -= 1
                } else {
                    transcription.status = "available"
                    transcription.url = transcriptURL(archiveId: archive.id)
                }
                archive.transcription = transcription
            } else {
                archive.status = "available"
                archive.url = archive.url ?? "https://example.com/e2e/archive-\(archive.id).mp4"
            }
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
        let isTranscription = archive.transcription != nil

        var remoteArchive: [String: Any] = [
            "id": archive.id,
            "status": archive.status,
            "name": archive.name,
            "reason": NSNull(),
            "sessionId": session.sessionId,
            "applicationId": session.applicationId,
            // The real backend reports milliseconds since the Unix epoch.
            "createdAt": archive.createdAt * 1000,
            "size": 1_024_000,
            "duration": 10,
            "outputMode": isTranscription ? "individual" : "composed",
            "streamMode": "auto",
            "hasAudio": true,
            "hasVideo": !isTranscription,
            "hasTranscription": isTranscription,
            "sha256sum": "e2e-sha256",
            "password": "",
            "updatedAt": Date().timeIntervalSince1970,
            "multiArchiveTag": "",
            "event": "archive",
            "resolution": "640x480",
            "url": archive.url as Any,
        ]

        if let transcription = archive.transcription {
            remoteArchive["transcription"] = [
                "status": transcription.status,
                "url": transcription.url as Any,
            ]
        }

        return remoteArchive
    }

    /// Serves the transcript as a local empty zip so it downloads without a network.
    private func transcriptURL(archiveId: String) -> String {
        let emptyZip = Data([0x50, 0x4B, 0x05, 0x06] + Array(repeating: 0, count: 18))
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("e2e-transcription-\(archiveId).zip")
        try? emptyZip.write(to: fileURL)
        return fileURL.absoluteString
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
