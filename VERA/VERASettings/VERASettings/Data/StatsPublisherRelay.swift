import Combine
import VERADomain

/// The narrowly scoped Sendable boundary for the repository's Combine subject.
///
/// Safety contract: the subject reference is fixed and private, and accessed only
/// through Combine's synchronized send/subscription operations. Outputs are checked
/// Sendable snapshots. Each owning repository actor serializes writes. Downstream
/// closures must protect their captured state and select their own delivery scheduler.
///
/// This relies on Combine's synchronization, not compiler verification of the subject:
/// https://forums.swift.org/t/thread-safety-for-combine-publishers/29491/11
/// No extra lock is held across downstream callbacks, which may subscribe or cancel.
final class StatsPublisherRelay: @unchecked Sendable {
    private let subject = CurrentValueSubject<NetworkMediaStats, Never>(.empty)

    var publisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.eraseToAnyPublisher()
    }

    func send(_ stats: NetworkMediaStats) {
        subject.send(stats)
    }
}
