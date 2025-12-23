//
//  Created by Vonage on 23/12/25.
//

import Foundation

public enum ToastMode {
    case warning, info, failure, success
}

public struct ToastItem: Equatable {
    public let message: String
    public let mode: ToastMode

    public init(message: String, mode: ToastMode) {
        self.message = message
        self.mode = mode
    }
}
