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

    public init(
        id: String,
        name: String,
        isMicEnabled: Bool,
        isCameraEnabled: Bool,
        view: AnyView
    ) {
        self.id = id
        self.name = name
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.view = view
    }

    public static func == (lhs: Participant, rhs: Participant) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.isMicEnabled == rhs.isMicEnabled
            && lhs.isCameraEnabled == rhs.isCameraEnabled
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(isMicEnabled)
        hasher.combine(isCameraEnabled)
    }
}
