import Foundation

/// Native SDK error domains are required: identical numeric codes have different meanings across domains.
enum VideoRecoveryPolicy {
    case connection
    case subscriber
    case publisher

    func permits(_ error: Error) -> Bool {
        let error = error as NSError
        switch self {
        case .subscriber:
            return error.domain == "OTSubscriberErrorDomain" && error.code == 1542
        case .publisher:
            return error.domain == "OTPublisherErrorDomain" && error.code == 1610
        case .connection:
            return error.domain == "OTSessionErrorDomain" && [1006, 1020, 1021, 1023, 1503].contains(error.code)
        }
    }
}
