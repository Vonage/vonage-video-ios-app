//
//  Created by Vonage on 23/12/25.
//

import Foundation

public enum ToastMode {
    case warning, info, failure, success

    /// A stable string used for accessibility identifiers.
    public var accessibilityName: String {
        switch self {
        case .warning: "warning"
        case .info: "info"
        case .failure: "failure"
        case .success: "success"
        }
    }
}

public struct ToastItem: Equatable {
    public let message: String
    public let mode: ToastMode

    public init(message: String, mode: ToastMode) {
        self.message = message
        self.mode = mode
    }
}
