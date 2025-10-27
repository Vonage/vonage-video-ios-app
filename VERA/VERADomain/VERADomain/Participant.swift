//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

public struct Participant: Identifiable, Hashable, Equatable, CustomStringConvertible {
    public let id: String
    public let name: String
    public let isMicEnabled: Bool
    public let isCameraEnabled: Bool
    public let view: AnyView
    public let videoDimensions: CGSize
    public let isRemote: Bool
    public let creationTime: Date
    public let isScreenshare: Bool
    public let isPinned: Bool

    public var onAppear: (() -> Void)?
    public var onDisappear: (() -> Void)?

    public init(
        id: String,
        name: String,
        isMicEnabled: Bool,
        isCameraEnabled: Bool,
        videoDimensions: CGSize,
        isRemote: Bool = true,
        creationTime: Date,
        isScreenshare: Bool,
        isPinned: Bool,
        view: AnyView
    ) {
        self.id = id
        self.name = name
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.videoDimensions = videoDimensions
        self.isRemote = isRemote
        self.creationTime = creationTime
        self.isScreenshare = isScreenshare
        self.isPinned = isPinned
        self.view = view
    }

    public var withEmptyView: Participant {
        Participant(
            id: id,
            name: name,
            isMicEnabled: isMicEnabled,
            isCameraEnabled: isCameraEnabled,
            videoDimensions: videoDimensions,
            isRemote: isRemote,
            creationTime: creationTime,
            isScreenshare: isScreenshare,
            isPinned: isPinned,
            view: AnyView(EmptyView()))
    }

    public static func == (lhs: Participant, rhs: Participant) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.isMicEnabled == rhs.isMicEnabled
            && lhs.isCameraEnabled == rhs.isCameraEnabled && lhs.videoDimensions == rhs.videoDimensions
            && lhs.isRemote == rhs.isRemote
            && lhs.creationTime == rhs.creationTime
            && lhs.isScreenshare == rhs.isScreenshare
            && lhs.isPinned == rhs.isPinned
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
        hasher.combine(isScreenshare)
        hasher.combine(isPinned)
    }

    public var containerAspectRatio: Double {
        let dimensions = videoDimensions
        guard dimensions.height > 0 else { return 16.0 / 9.0 }
        var ratio = Double(dimensions.width / dimensions.height)
        if ratio < 1 {
            ratio = 1.33
        }
        return ratio
    }

    public var aspectRatio: Double {
        guard videoDimensions.height > 0 else { return 16.0 / 9.0 }
        return Double(videoDimensions.width / videoDimensions.height)
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        return """
            Participant(id: "\(id)", name: "\(name)", isMicEnabled: \(isMicEnabled), \
            isCameraEnabled: \(isCameraEnabled) \
            isRemote: \(isRemote), isScreenshare: \(isScreenshare), \
            isPinned: \(isPinned))
            """
    }
}
