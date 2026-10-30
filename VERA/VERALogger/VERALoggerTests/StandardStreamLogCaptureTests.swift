//
//  Created by Vonage on 30/10/26.
//

import Darwin
import Foundation
import Testing

@testable import VERALogger

@Suite("Standard stream log capture", .serialized)
struct StandardStreamLogCaptureTests {

    @Test("Console output is appended to the rotating files")
    func startAppendsConsoleOutput() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("veralogger-capture-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let files = RotatingLogFileSet(directory: directory, maxFileSize: 4096, maxFileCount: 2)
        let capture = StandardStreamLogCapture(fileSet: files)

        // `start` redirects this process's standard streams. Put them back before the
        // rest of the logger suite continues.
        let savedStdout = dup(STDOUT_FILENO)
        let savedStderr = dup(STDERR_FILENO)
        defer {
            if savedStdout >= 0 {
                _ = dup2(savedStdout, STDOUT_FILENO)
                _ = close(savedStdout)
            }
            if savedStderr >= 0 {
                _ = dup2(savedStderr, STDERR_FILENO)
                _ = close(savedStderr)
            }
        }

        await capture.start()
        let token = "veralogger-capture-\(UUID().uuidString)"
        var line = Data("\(token)\n".utf8)
        line.withUnsafeBytes { buffer in
            guard let address = buffer.baseAddress else { return }
            _ = Darwin.write(STDOUT_FILENO, address, buffer.count)
        }

        let deadline = Date().addingTimeInterval(2)
        var transcript = ""
        while Date() < deadline {
            let urls = await files.fileURLs()
            transcript = urls.compactMap { try? String(contentsOf: $0, encoding: .utf8) }.joined()
            if transcript.contains(token) { break }
            try await Task.sleep(for: .milliseconds(20))
        }

        #expect(transcript.contains(token))
        await capture.start()
    }
}
