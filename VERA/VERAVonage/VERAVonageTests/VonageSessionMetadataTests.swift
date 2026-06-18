import Testing
import VERAVonage

@Suite("Vonage session metadata tests")
struct VonageSessionMetadataTests {

    @Test("session exposes session id and nil connection metadata before connect")
    func sessionExposesMetadataBeforeConnect() {
        let session = VonageSessionSpy()

        #expect(session.sessionId == "sessionId")
        #expect(session.connectionId == nil)
        #expect(session.connectionCreationTime == nil)
    }
}
