import Foundation

/// Native SDK error domains are required: identical numeric codes have different meanings across domains.
enum VideoRecoveryPolicy {
    case connection

    func permits(_ error: Error) -> Bool {
        let error = error as NSError
        switch self {
        case .connection:
            return error.domain == "OTSessionErrorDomain" && [1006, 1020, 1021, 1023, 1503].contains(error.code)
        }
    }
}
