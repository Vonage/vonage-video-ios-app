//
//  Created by Vonage on 24/04/2026.
//

import Testing
import VERADomain

@Suite("VideoCodecPreference tests")
struct VideoCodecPreferenceTests {

    // MARK: - Init

    @Test("Given automatic true and nil codecs, when initialised, then properties match")
    func initAutomaticWithNilCodecs() {
        let sut = VideoCodecPreference(automatic: true, codecs: nil)

        #expect(sut.automatic == true)
        #expect(sut.codecs == nil)
    }

    @Test("Given automatic false and codec list, when initialised, then properties match")
    func initManualWithCodecList() {
        let sut = VideoCodecPreference(automatic: false, codecs: [.vp8, .h264, .vp9])

        #expect(sut.automatic == false)
        #expect(sut.codecs == [.vp8, .h264, .vp9])
    }

    // MARK: - Equatable

    @Test("Given two identical preferences, then they are equal")
    func identicalPreferencesAreEqual() {
        let lhs = VideoCodecPreference(automatic: false, codecs: [.h264])
        let rhs = VideoCodecPreference(automatic: false, codecs: [.h264])

        #expect(lhs == rhs)
    }

    @Test("Given preferences with different automatic flag, then they are not equal")
    func preferencesWithDifferentAutomaticFlagAreNotEqual() {
        let lhs = VideoCodecPreference(automatic: true, codecs: nil)
        let rhs = VideoCodecPreference(automatic: false, codecs: nil)

        #expect(lhs != rhs)
    }

    @Test("Given preferences with different codec lists, then they are not equal")
    func preferencesWithDifferentCodecListsAreNotEqual() {
        let lhs = VideoCodecPreference(automatic: false, codecs: [.vp8])
        let rhs = VideoCodecPreference(automatic: false, codecs: [.h264])

        #expect(lhs != rhs)
    }

    // MARK: - Hashable

    @Test("Given two equal preferences, then their hash values are equal")
    func equalPreferencesHaveEqualHashValues() {
        let lhs = VideoCodecPreference(automatic: false, codecs: [.vp9])
        let rhs = VideoCodecPreference(automatic: false, codecs: [.vp9])

        #expect(lhs.hashValue == rhs.hashValue)
    }

    @Test("Given preference instances, then they can be used as Set elements")
    func preferencesCanBeUsedInSet() {
        let preference = VideoCodecPreference(automatic: true, codecs: nil)
        var set: Set<VideoCodecPreference> = []

        set.insert(preference)
        set.insert(preference)

        #expect(set.count == 1)
    }
}
