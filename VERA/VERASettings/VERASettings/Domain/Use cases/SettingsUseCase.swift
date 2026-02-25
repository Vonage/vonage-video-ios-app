//
//  Created by Vonage on 25/2/26.
//

import Foundation

public struct SettingsRequest {
    public let param: String

    public init(param: String) {
        self.param = param
    }
}

public protocol SettingsUseCase {
    func callAsFunction(_ request: SettingsRequest) async throws
}

public final class DefaultSettingsUseCase: SettingsUseCase {
    public init() {
    }

    public func callAsFunction(
        _ request: SettingsRequest
    ) async throws {
    }
}
