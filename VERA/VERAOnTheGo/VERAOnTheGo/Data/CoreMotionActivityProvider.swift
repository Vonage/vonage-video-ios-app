//
//  Created by Vonage on 17/10/26.
//

#if canImport(CoreMotion) && !os(macOS)
    import CoreMotion
    import Foundation

    /// ``MotionActivityProviding`` backed by `CMMotionActivityManager`.
    ///
    /// iOS only — CoreMotion is unavailable on macOS, so callers pass `nil`
    /// there instead.
    @MainActor
    public final class CoreMotionActivityProvider: MotionActivityProviding {

        private let activityManager = CMMotionActivityManager()

        public init() {}

        public var isAvailable: Bool {
            CMMotionActivityManager.isActivityAvailable()
        }

        public var authorizationStatus: MotionAuthorizationStatus {
            guard isAvailable else { return .unavailable }
            switch CMMotionActivityManager.authorizationStatus() {
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
            case .denied: return .denied
            case .authorized: return .authorized
            @unknown default: return .unavailable
            }
        }

        public func start(_ handler: @escaping @MainActor (MotionSample) -> Void) {
            activityManager.startActivityUpdates(to: .main) { activity in
                guard let activity else { return }
                let sample = MotionSample(activity)
                Task { @MainActor in
                    handler(sample)
                }
            }
        }

        public func stop() {
            activityManager.stopActivityUpdates()
        }
    }

    extension MotionSample {
        init(_ activity: CMMotionActivity) {
            let kind: Kind =
                if activity.automotive {
                    .automotive
                } else if activity.cycling {
                    .cycling
                } else if activity.running {
                    .running
                } else if activity.walking {
                    .walking
                } else if activity.stationary {
                    .stationary
                } else {
                    .unknown
                }

            let confidence: Confidence =
                switch activity.confidence {
                case .low: .low
                case .medium: .medium
                case .high: .high
                @unknown default: .low
                }

            self.init(kind: kind, confidence: confidence, timestamp: activity.startDate)
        }
    }
#endif
