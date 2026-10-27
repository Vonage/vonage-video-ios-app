//
//  Created by Vonage on 26/10/26.
//

import Foundation

/// Captures everything written to the standard output and error streams and appends it to a
/// ``RotatingLogFileSet``.
///
/// The Vonage SDK writes its logs straight to `stdout`, which is also where `NSLog`, `OSLog`
/// and the rest of the console output end up. Redirecting the file descriptors is therefore
/// the only way to persist the full console transcript without filtering.
///
/// The original `stdout` is duplicated before the redirection and every captured chunk is
/// mirrored back to it, so the Xcode console keeps showing the logs while debugging.
///
/// Captured chunks are delivered through an `AsyncStream`, so a single consumer task writes
/// them to disk in order without any locking.
public actor StandardStreamLogCapture {

    private let fileSet: RotatingLogFileSet
    private var isCapturing = false
    private var pipe: Pipe?
    private var consumerTask: Task<Void, Never>?

    /// Creates a capture that appends console output to the given file set.
    ///
    /// - Parameter fileSet: Destination of the captured output.
    public init(fileSet: RotatingLogFileSet) {
        self.fileSet = fileSet
    }

    /// Starts redirecting the standard streams to the log files.
    ///
    /// Calling this more than once has no effect.
    public func start() {
        guard !isCapturing else { return }
        isCapturing = true

        // Keep a handle on the real console so the output is still visible in Xcode.
        let consoleDescriptor = dup(STDOUT_FILENO)
        // The SDK writes through the C runtime, which buffers when stdout is not a TTY.
        // Unbuffered output makes sure nothing is lost if the app is killed.
        setvbuf(stdout, nil, _IONBF, 0)

        let pipe = Pipe()
        self.pipe = pipe
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        let stream = AsyncStream<Data> { continuation in
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                data.withUnsafeBytes { buffer in
                    guard let address = buffer.baseAddress else { return }
                    _ = Darwin.write(consoleDescriptor, address, buffer.count)
                }
                continuation.yield(data)
            }
            continuation.onTermination = { _ in
                pipe.fileHandleForReading.readabilityHandler = nil
            }
        }

        consumerTask = Task { [fileSet] in
            for await data in stream {
                await fileSet.write(data)
            }
        }
    }
}
