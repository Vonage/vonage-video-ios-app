//
//  Created by Vonage on 23/1/26.
//

import Foundation
import OpenTok
import VERAVonage
import VonageClientSDKVideo

public struct BackgroundBlur {
    public static let key = "BackgroundBlur"

    public enum Error: Swift.Error {
        case encodingError
        case videoTransformerInitializationError
        case unexpectedType
    }

    public init() {
    }

    public func params(blurLevel: BlurLevel) throws -> String {
        let data = try JSONEncoder().encode(Radius(radius: blurLevel))

        guard let properties = String(data: data, encoding: .utf8) else {
            throw Error.encodingError
        }
        return properties
    }
}

public struct Radius: Codable {
    public let radius: BlurLevel

    public init(radius: BlurLevel) {
        self.radius = radius
    }
}

public enum BlurLevel: String, Codable {
    case low = "Low"
    case high = "High"
    case none = "None"
}
