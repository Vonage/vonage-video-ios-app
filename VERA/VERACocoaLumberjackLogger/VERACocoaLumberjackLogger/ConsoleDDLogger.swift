//
//  Created by Vonage on 8/4/26.
//

import CocoaLumberjackSwift
import Foundation

// swiftlint:disable no_print
/// A CocoaLumberjack logger that writes to standard output via `print()`.
///
/// Use this when you want direct Xcode console output without os_log formatting.
/// CocoaLumberjack provides `DDOSLogger` for os_log and `DDFileLogger` for files,
/// but no simple print-based logger — this fills that gap.
public final class ConsoleDDLogger: DDAbstractLogger {

    override public func log(message logMessage: DDLogMessage) {
        print(logMessage.message)
    }
}
// swiftlint:enable no_print
