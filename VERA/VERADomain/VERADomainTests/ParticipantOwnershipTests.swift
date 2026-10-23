import SwiftUI
import Testing

@testable import VERADomain

@Suite("Participant UI ownership")
@MainActor
struct ParticipantOwnershipTests {
    @Test("Metadata and participant snapshots cross actors without exposing the renderable view")
    func metadataTransfer() async {
        let participant = Participant(
            id: "participant", connectionId: "connection", name: "Alice",
            isMicEnabled: true, isCameraEnabled: true,
            videoDimensions: CGSize(width: 640, height: 360),
            creationTime: .distantPast, isScreenshare: false,
            view: AnyView(Text("Video")))
        let snapshot = ParticipantsState(
            localParticipant: participant, participants: [participant], activeParticipantId: participant.id)

        let matches = await Task.detached {
            let remote = snapshot.participants[0]
            return remote == participant && Set([remote, participant]).count == 1
                && remote.name == "Alice" && remote.aspectRatio == 640.0 / 360.0
                && snapshot.localParticipant?.connectionId == "connection"
        }.value
        #expect(matches)
    }

    @Test("Visibility callbacks execute on the UI owner and empty-view teardown preserves metadata")
    func visibilityAndCleanup() {
        var appearances = 0
        var participant = Participant(
            id: "participant", name: "Alice", isMicEnabled: true, isCameraEnabled: false,
            videoDimensions: .zero, creationTime: .distantPast,
            isScreenshare: false, view: AnyView(EmptyView()))
        participant.onAppear = { appearances += 1 }
        participant.onAppear?()
        #expect(appearances == 1)
        #expect(participant.withEmptyView == participant)
        #expect(participant.withEmptyView.onAppear == nil)
        #expect(participant.containerAspectRatio == 16.0 / 9.0)
        #expect(participant.aspectRatio == 16.0 / 9.0)
        #expect(participant.description.contains("Alice"))
    }
}
