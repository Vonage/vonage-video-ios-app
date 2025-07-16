//
//  Created by Vonage on 16/7/25.
//

import Foundation

public struct UICameraDevice: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let iconName: String

    public var onTap: (() -> Void)?

    public init(id: String, name: String, iconName: String) {
        self.id = id
        self.name = name
        self.iconName = iconName
    }

    public static func == (lhs: UICameraDevice, rhs: UICameraDevice) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.iconName == rhs.iconName
    }
}
