import Foundation
import Testing
import VERADomain

@testable import VERAVonage

@MainActor
@Suite("VonageSessionFactory tests")
struct VonageSessionFactoryTests {
    @Test("Native sessions use the main callback queue before delegate installation")
    func configuresNativeSessionBeforeUse() throws {
        let sut = VonageSessionFactory()
        let session = try sut.makeOTSession(makeCredentials())

        #expect(session.apiQueue === DispatchQueue.main)
        #expect(session.delegate == nil)
    }

    @Test("Factory wraps the configured native session with the supplied credentials")
    func makesConfiguredWrapper() throws {
        let sut = VonageSessionFactory()
        let session = try sut.make(makeCredentials())

        #expect(session.roomName == "heart-of-gold")
        #expect(session.applicationId == "applicationId")
    }

    private func makeCredentials() -> RoomCredentials {
        RoomCredentials(
            sessionId: "sessionId",
            token: "token",
            applicationId: "applicationId",
            roomName: "heart-of-gold",
            sessionKey: "sessionKey"
        )
    }
}
