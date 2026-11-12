//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import Testing

@testable import VERASettings

@Suite("Persisted codec preference value transfer")
struct CodecPreferenceTransferTests {

    @Test("Persisted automatic and manual preferences retain codec ordering across tasks and an actor")
    func persistedPreferencesAcrossTasksAndActor() async throws {
        let fixtures: [(String, SettingsCodecMode, [SettingsVideoCodec])] = [
            (#"{"mode":"automatic","orderedCodecs":[3,1,2]}"#, .automatic, [.vp9, .vp8, .h264]),
            (#"{"mode":"automatic","orderedCodecs":[]}"#, .automatic, []),
            (#"{"mode":"manual","orderedCodecs":[]}"#, .manual, []),
            (#"{"mode":"manual","orderedCodecs":[2,3,1]}"#, .manual, [.h264, .vp9, .vp8]),
        ]
        let selection = CodecSelection()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        for (json, mode, codecs) in fixtures {
            let preference = try JSONDecoder().decode(SettingsCodecPreference.self, from: Data(json.utf8))
            let transferred = await Task.detached { preference }.value
            await selection.update(transferred)
            let received = await selection.preference

            #expect(received.mode == mode)
            #expect(received.orderedCodecs == codecs)
            #expect(String(decoding: try encoder.encode(received), as: UTF8.self) == json)

            let domainPreference = received.vonageCodecPreference
            #expect(domainPreference.automatic == (mode == .automatic))
            #expect(domainPreference.codecs?.map(\.rawValue) == codecs.map(\.rawValue))
        }
    }

    @Test("Editing a transferred mutable preference leaves the original and actor snapshot unchanged")
    func copiesRemainIndependent() async {
        let original = SettingsCodecPreference.automatic
        let edited = await Task.detached {
            var copy = original
            copy.mode = .manual
            copy.orderedCodecs.reverse()
            return copy
        }.value

        #expect(original.mode == .automatic)
        #expect(original.orderedCodecs == [.vp9, .vp8, .h264])
        #expect(edited.mode == .manual)
        #expect(edited.orderedCodecs == [.h264, .vp8, .vp9])

        let selection = CodecSelection()
        await selection.update(edited)
        var readCopy = await selection.preference
        readCopy.mode = .automatic
        readCopy.orderedCodecs.removeAll()

        let stored = await selection.preference
        #expect(readCopy.orderedCodecs.isEmpty)
        #expect(stored.mode == .manual)
        #expect(stored.orderedCodecs == [.h264, .vp8, .vp9])
        #expect(SettingsCodecPreference.automatic.orderedCodecs == [.vp9, .vp8, .h264])
    }

    @Test("Static defaults, case order, raw values, identifiers and codec labels remain compatible")
    func defaultsAndCodecRepresentations() {
        #expect(SettingsCodecPreference().mode == .automatic)
        #expect(SettingsCodecPreference().orderedCodecs == [.vp9, .vp8, .h264])
        #expect(SettingsCodecPreference.defaultManual.mode == .manual)
        #expect(SettingsCodecPreference.defaultManual.orderedCodecs == [.vp9, .vp8, .h264])
        #expect(SettingsCodecMode.allCases.map(\.rawValue) == ["automatic", "manual"])
        #expect(SettingsCodecMode.allCases.map(\.id) == ["automatic", "manual"])
        #expect(SettingsVideoCodec.allCases.map(\.rawValue) == [1, 2, 3])
        #expect(SettingsVideoCodec.allCases.map(\.id) == [1, 2, 3])
        #expect(SettingsVideoCodec.allCases.map(\.displayName) == ["VP8", "H.264", "VP9"])
    }
}

private actor CodecSelection {
    private(set) var preference = SettingsCodecPreference.automatic

    func update(_ value: SettingsCodecPreference) {
        preference = value
    }
}
