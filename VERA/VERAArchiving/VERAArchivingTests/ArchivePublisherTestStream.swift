import Combine

/// Subscribes on the test actor and transfers only checked values into async iteration.
/// The caller retains and cancels the subscription on the same actor.
@MainActor
func makeArchivePublisherTestStream<Value: Sendable>(
    from publisher: AnyPublisher<Value, Error>
) -> (stream: AsyncThrowingStream<Value, Error>, subscription: AnyCancellable) {
    let (stream, continuation) = AsyncThrowingStream<Value, Error>.makeStream()
    let subscription = publisher.sink(
        receiveCompletion: { @Sendable completion in
            switch completion {
            case .finished:
                continuation.finish()
            case .failure(let error):
                continuation.finish(throwing: error)
            }
        },
        receiveValue: { @Sendable value in continuation.yield(value) }
    )
    return (stream, subscription)
}
