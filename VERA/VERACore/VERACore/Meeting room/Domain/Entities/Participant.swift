//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

public struct Participant: Identifiable, Hashable, Equatable {
    public let id: String
    public let name: String
    public let isMicEnabled: Bool
    public let isCameraEnabled: Bool
    public let view: AnyView
    public let videoDimensions: CGSize
    public let isRemote: Bool
    public let creationTime: Date
    public let audioLevel: Float

    public init(
        id: String,
        name: String,
        isMicEnabled: Bool,
        isCameraEnabled: Bool,
        videoDimensions: CGSize,
        isRemote: Bool = true,
        creationTime: Date,
        audioLevel: Float,
        view: AnyView
    ) {
        self.id = id
        self.name = name
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.videoDimensions = videoDimensions
        self.isRemote = isRemote
        self.creationTime = creationTime
        self.audioLevel = audioLevel
        self.view = view
    }

    public static func == (lhs: Participant, rhs: Participant) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.isMicEnabled == rhs.isMicEnabled
            && lhs.isCameraEnabled == rhs.isCameraEnabled && lhs.videoDimensions == rhs.videoDimensions
            && lhs.isRemote == rhs.isRemote
            && lhs.creationTime == rhs.creationTime
            && lhs.audioLevel == rhs.audioLevel
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(isMicEnabled)
        hasher.combine(isCameraEnabled)
        hasher.combine(videoDimensions.width)
        hasher.combine(videoDimensions.height)
        hasher.combine(isRemote)
        hasher.combine(creationTime)
        hasher.combine(audioLevel)
    }

    public var aspectRatio: Double {
        let dimensions = videoDimensions
        var ratio = Double(dimensions.width / dimensions.height)
        if ratio < 1 {
            ratio = 1.33
        }
        return ratio
    }
}
