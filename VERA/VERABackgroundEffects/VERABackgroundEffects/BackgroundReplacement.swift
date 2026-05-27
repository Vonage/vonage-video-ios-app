//
//  Created by Vonage on 18/05/2026.
//

import Foundation
import OpenTok
import VERADomain
import VERAVonage
import VonageClientSDKVideo

public struct BackgroundReplacement {
    public static let key = "BackgroundReplacement"

    public enum Error: Swift.Error {
        case encodingError
        case videoTransformerInitializationError
    }

    public init() {}

    public func params(imagePath: String) throws -> String {
        let data = try JSONEncoder().encode(ImageParams(imageFilePath: imagePath))

        guard let properties = String(data: data, encoding: .utf8) else {
            throw Error.encodingError
        }
        return properties
    }
}

public struct ImageParams: Codable {
    public let imageFilePath: String

    enum CodingKeys: String, CodingKey {
        case imageFilePath = "image_file_path"
    }

    public init(imageFilePath: String) {
        self.imageFilePath = imageFilePath
    }
}
