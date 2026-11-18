//
//  Created by Vonage on 11/10/26.
//

import Testing
import VERADomain

@Suite("ArchiveKind tests")
struct ArchiveKindTests {

    @Test("Transcription archive name maps to transcription")
    func transcriptionNameMapsToTranscription() {
        #expect(ArchiveKind(archiveName: "transcription") == .transcription)
    }

    @Test("Recording archive name maps to recording")
    func recordingNameMapsToRecording() {
        #expect(ArchiveKind(archiveName: "recording") == .recording)
    }

    @Test(
        "Missing or unknown archive names fall back to recording",
        arguments: [nil, "", "Vonage Video Session", "Transcription"])
    func unknownNamesFallBackToRecording(_ name: String?) {
        #expect(ArchiveKind(archiveName: name) == .recording)
    }
}
