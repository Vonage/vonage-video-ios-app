import Combine

/// A narrowly scoped concurrency boundary for a private Combine subject.
///
/// Output values are checked Sendable. Combine synchronizes subscription storage,
/// value access and downstream delivery; owning actors remain responsible for the
/// ordering of compound read/modify/send operations. No additional lock is held
/// while downstream code runs. Subscribers choose their own delivery scheduler
/// and must protect any mutable state captured by their closures.
///
/// The unchecked conformance covers the encapsulated legacy subject and its
/// immutable, type-erased publisher view:
/// https://forums.swift.org/t/thread-safety-for-combine-publishers/29491/13
public final class CurrentValueRelay<Output: Sendable, Failure: Error>: @unchecked Sendable {
    private let subject: CurrentValueSubject<Output, Failure>
    public let publisher: AnyPublisher<Output, Failure>

    public init(_ value: Output) {
        let subject = CurrentValueSubject<Output, Failure>(value)
        self.subject = subject
        publisher = subject.eraseToAnyPublisher()
    }

    public var value: Output { subject.value }

    public func send(_ value: Output) {
        subject.send(value)
    }

    public func send(completion: Subscribers.Completion<Failure>) {
        subject.send(completion: completion)
    }
}

/// A non-replaying event relay with the same synchronization contract as CurrentValueRelay.
public final class EventRelay<Output: Sendable, Failure: Error>: @unchecked Sendable {
    private let subject: PassthroughSubject<Output, Failure>
    public let publisher: AnyPublisher<Output, Failure>

    public init() {
        let subject = PassthroughSubject<Output, Failure>()
        self.subject = subject
        publisher = subject.eraseToAnyPublisher()
    }

    public func send(_ value: Output) {
        subject.send(value)
    }

    public func send(completion: Subscribers.Completion<Failure>) {
        subject.send(completion: completion)
    }
}
