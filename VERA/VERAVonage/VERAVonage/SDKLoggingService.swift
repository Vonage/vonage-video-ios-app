//
//  Created by Vonage on 21/5/26.
//

import Foundation
import VERALogger

/// Sets the SDK log level. 0 = disabled, 1 = error, 2 = warn, 3 = info, 4 = debug.
@_silgen_name("otc_log_enable")
private func otc_log_enable(_ level: Int32)

/// Manages Vonage Video SDK log capture to file.
///
/// Call `configure(enabled:logLevel:)` early in the app lifecycle (before any
/// `OTSession` is created) so that SDK console output is captured from the start.
///
/// The SDK writes log messages to stderr. This service redirects stderr through a
/// pipe so that every message is both forwarded to the original stderr (keeping the
/// Xcode console working) and written to rotating log files managed by a
/// ``FileLogStrategy`` in rolling mode.
public final class SDKLoggingService: @unchecked Sendable {

    private let fileStrategy: FileLogStrategy

    // stderr capture state
    private var savedStderrFd: Int32 = -1
    private var capturePipe: Pipe?
    private var readSource: DispatchSourceRead?

    /// Creates the service.
    ///
    /// - Parameter logsDirectory: The directory where log files are stored.
    public init(fileStrategy: FileLogStrategy) {
        self.fileStrategy = fileStrategy
    }

    /// Configures SDK logging.
    ///
    /// - Parameters:
    ///   - enabled: Whether to enable SDK log capture.
    ///   - logLevel: The SDK log level (0 = disabled, 1 = error … 4 = debug).
    ///     The SDK itself performs the level filtering; the file captures everything
    ///     the SDK outputs.
    public func configure(enabled: Bool, logLevel: Int) {
        if enabled {
            // Write a startup marker so a log file exists immediately.
            let marker = LogEvent(
                level: .info, tag: "SDKLogging", message: "SDK file logging started (level: \(logLevel))")
            fileStrategy.log(marker)

            startStderrCapture(strategy: fileStrategy)

            let otcLevel = Self.mapToOTCLevel(rawValue: logLevel)
            otc_log_enable(otcLevel)
        } else {
            stopStderrCapture()
            otc_log_enable(0)
        }
    }

    /// Deletes all existing log files.
    public func clearLogFiles() {
        fileStrategy.deleteAllLogFiles()

    }

    /// Returns URLs for all current log files.
    public func getLogFileURLs() -> [URL] {
        return fileStrategy.allLogFileURLs()
    }

    // MARK: - stderr Capture

    /// Redirects stderr through a pipe so output is tee'd to the log file
    /// while still forwarding to the original stderr (Xcode console).
    private func startStderrCapture(strategy: FileLogStrategy) {
        guard savedStderrFd == -1 else { return }

        // Save the original stderr file descriptor.
        let originalFd = dup(STDERR_FILENO)
        guard originalFd >= 0 else { return }
        savedStderrFd = originalFd

        let pipe = Pipe()
        self.capturePipe = pipe

        // Point stderr at the pipe's write end.
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        // Set up a GCD read source on the pipe's read end.
        let readFd = pipe.fileHandleForReading.fileDescriptor
        let source = DispatchSource.makeReadSource(fileDescriptor: readFd, queue: .global(qos: .utility))
        self.readSource = source

        source.setEventHandler { [weak strategy] in
            let bufferSize = 8192
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }

            let bytesRead = read(readFd, buffer, bufferSize)
            guard bytesRead > 0 else { return }

            // Forward to the original stderr so Xcode console still works.
            var remaining = bytesRead
            var offset = 0
            while remaining > 0 {
                let written = Darwin.write(originalFd, buffer.advanced(by: offset), remaining)
                if written <= 0 { break }
                offset += written
                remaining -= written
            }

            // Write raw bytes to the log file.
            if let text = String(bytes: UnsafeBufferPointer(start: buffer, count: bytesRead), encoding: .utf8) {
                strategy?.writeRaw(text)
            }
        }

        source.setCancelHandler { [weak self] in
            self?.capturePipe?.fileHandleForReading.closeFile()
        }

        source.resume()
    }

    /// Restores the original stderr and tears down the capture pipe.
    private func stopStderrCapture() {
        readSource?.cancel()
        readSource = nil

        if savedStderrFd >= 0 {
            // Restore original stderr.
            dup2(savedStderrFd, STDERR_FILENO)
            close(savedStderrFd)
            savedStderrFd = -1
        }

        capturePipe?.fileHandleForWriting.closeFile()
        capturePipe = nil
    }

    // MARK: - Level Mapping

    /// Maps SDKLogLevel raw value to the OTC log level expected by `otc_log_enable`.
    ///
    /// - Parameter rawValue: The raw value from ``SDKLogLevel`` (0 = verbose … 4 = error).
    /// - Returns: The corresponding OTC level (4 = debug … 1 = error, default = 4).
    static func mapToOTCLevel(rawValue: Int) -> Int32 {
        switch rawValue {
        case 0: return 4  // verbose → debug (most permissive SDK level)
        case 1: return 4  // debug
        case 2: return 3  // info
        case 3: return 2  // warn
        case 4: return 1  // error
        default: return 4
        }
    }
}
