//
//  Created by Vonage on 16/4/26.
//

import Foundation
import Testing
import VERADomain
import VERAMeetingRoom

@testable import VERAMeetingRoomSDK

@Suite("MeetingRoomFeature tests")
struct MeetingRoomFeatureTests {

    @Test("All features are available via CaseIterable")
    func allFeaturesAvailable() {
        let allFeatures = MeetingRoomFeature.allCases
        #expect(allFeatures.count == 8)
        #expect(allFeatures.contains(.chat))
        #expect(allFeatures.contains(.archiving))
        #expect(allFeatures.contains(.captions))
        #expect(allFeatures.contains(.reactions))
        #expect(allFeatures.contains(.settings))
        #expect(allFeatures.contains(.screenShare))
        #expect(allFeatures.contains(.backgroundEffects))
        #expect(allFeatures.contains(.audioEffects))
    }

    @Test("Features are Hashable and can be stored in a Set")
    func featuresAreHashable() {
        let features: Set<MeetingRoomFeature> = [.chat, .captions, .chat]
        #expect(features.count == 2)
        #expect(features.contains(.chat))
        #expect(features.contains(.captions))
        #expect(!features.contains(.archiving))
    }

    @Test("Features have unique raw values")
    func featuresHaveUniqueRawValues() {
        let rawValues = MeetingRoomFeature.allCases.map(\.rawValue)
        let uniqueValues = Set(rawValues)
        #expect(rawValues.count == uniqueValues.count)
    }

    @Test("Empty feature set is valid")
    func emptyFeatureSet() {
        let features: Set<MeetingRoomFeature> = []
        #expect(features.isEmpty)
        #expect(!features.contains(.chat))
    }

    @Test("Full feature set contains all features")
    func fullFeatureSet() {
        let features = Set(MeetingRoomFeature.allCases)
        #expect(features.count == 8)
        for feature in MeetingRoomFeature.allCases {
            #expect(features.contains(feature))
        }
    }
}
