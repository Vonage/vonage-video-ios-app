//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

public class Participant: AnyObject, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let isMicEnabled: Bool
    public let isCameraEnabled: Bool
    public let view: AnyView
    public let videoDimensions: CGSize?
    public let isRemote: Bool
    public let creationTime: Date
    
    public init(
        id: String,
        name: String,
        isMicEnabled: Bool,
        isCameraEnabled: Bool,
        videoDimensions: CGSize?,
        isRemote: Bool = true,
        creationTime: Date,
        view: AnyView
    ) {
        self.id = id
        self.name = name
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.videoDimensions = videoDimensions
        self.isRemote = isRemote
        self.creationTime = creationTime
        self.view = view
    }

    public static func == (lhs: Participant, rhs: Participant) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.isMicEnabled == rhs.isMicEnabled
            && lhs.isCameraEnabled == rhs.isCameraEnabled && lhs.videoDimensions == rhs.videoDimensions
        && lhs.creationTime == rhs.creationTime
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(isMicEnabled)
        hasher.combine(isCameraEnabled)
        hasher.combine(videoDimensions?.width ?? 0)
        hasher.combine(videoDimensions?.height ?? 0)
        hasher.combine(isRemote)
        hasher.combine(creationTime)
    }

    public var aspectRatio: Double {
        guard let dimensions = videoDimensions,
            dimensions.width > 0 && dimensions.height > 0
        else {
            return 640.0 / 480.0
        }

        var ratio = Double(dimensions.width / dimensions.height)
        if ratio < 1 {
            ratio = 1.33
        }
        return ratio
    }
}
