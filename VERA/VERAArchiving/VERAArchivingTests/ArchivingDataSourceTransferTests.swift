//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERAArchiving

@Suite("Recording request and result value transfer")
struct ArchivingDataSourceTransferTests {

    @Test(
        "Start recording requests and results retain their fields across tasks and an actor",
        arguments: [("session", "archive"), ("", ""), ("会議-🎥", "録画-α")]
    )
    func startRecording(sessionKey: String, archiveID: String) async throws {
        let request = StartArchivingDataSourceRequest(sessionKey: sessionKey)
        let transferred = await Task.detached { request }.value
        #expect(transferred.sessionKey == sessionKey)

        let dataSource = RecordingDataSource(archiveID: archiveID)
        let response = try await dataSource.startArchiving(transferred)
        let received = await Task.detached { response }.value
        #expect(received.archiveId == archiveID)
        let recorded = await dataSource.startRequest
        #expect(recorded?.sessionKey == sessionKey)
    }

    @Test(
        "Stop recording requests and results retain their fields across tasks and an actor",
        arguments: [("session", "archive"), ("", ""), ("会議-🎥", "録画-α")]
    )
    func stopRecording(sessionKey: String, archiveID: String) async throws {
        let request = StopArchivingDataSourceRequest(sessionKey: sessionKey, archiveID: archiveID)
        let transferred = await Task.detached { request }.value
        #expect(transferred.sessionKey == sessionKey)
        #expect(transferred.archiveID == archiveID)

        let dataSource = RecordingDataSource(archiveID: archiveID)
        let response = try await dataSource.stopArchiving(transferred)
        let received = await Task.detached { response }.value
        #expect(received.archiveId == archiveID)
        let recorded = await dataSource.stopRequest
        #expect(recorded?.sessionKey == sessionKey)
        #expect(recorded?.archiveID == archiveID)
    }
}

private actor RecordingDataSource: ArchivingDataSource {
    private let archiveID: String
    private(set) var startRequest: StartArchivingDataSourceRequest?
    private(set) var stopRequest: StopArchivingDataSourceRequest?

    init(archiveID: String) {
        self.archiveID = archiveID
    }

    func startArchiving(_ request: StartArchivingDataSourceRequest) async throws -> StartArchivingDataSourceResponse {
        startRequest = request
        return .init(archiveId: archiveID)
    }

    func stopArchiving(_ request: StopArchivingDataSourceRequest) async throws -> StopArchivingDataSourceResponse {
        stopRequest = request
        return .init(archiveId: request.archiveID)
    }
}
