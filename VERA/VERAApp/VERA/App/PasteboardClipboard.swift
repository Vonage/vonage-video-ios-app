//
//  Created by Vonage on 13/8/25.
//

import Foundation
import UIKit
import VERACore

public final class PasteboardClipboard: Clipboard {
    public init() {}

    public func copy(_ string: String) {
        UIPasteboard.general.string = string
    }
}
