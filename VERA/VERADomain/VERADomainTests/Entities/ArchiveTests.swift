//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERADomain

@Suite("Archive tests")
struct ArchiveTests {

    // MARK: - ArchiveStatus

    @Test(
        "ArchiveStatus init(rawValue:) maps known strings correctly",
        arguments: [
            ("stopped", ArchiveStatus.stopped),
            ("available", ArchiveStatus.available),
        ])
    func archiveStatusInitRawValue(rawValue: String, expected: ArchiveStatus) {
        let status = ArchiveStatus(rawValue: rawValue)
        #expect(status == expected)
    }

    @Test("ArchiveStatus init(rawValue:) returns nil for unknown string")
    func archiveStatusInitRawValueReturnsNilForUnknown() {
        let status = ArchiveStatus(rawValue: "unknown")
        #expect(status == nil)
    }

    @Test("ArchiveStatus init(rawValue:) returns nil for failed string")
    func archiveStatusInitRawValueReturnsNilForFailed() {
        let status = ArchiveStatus(rawValue: "failed")
        #expect(status == nil)
    }

    @Test(
        "ArchiveStatus init(value:) maps known strings correctly",
        arguments: [
            ("stopped", ArchiveStatus.stopped),
            ("available", ArchiveStatus.available),
        ])
    func archiveStatusInitValue(value: String, expected: ArchiveStatus) {
        let status = ArchiveStatus(value: value)
        #expect(status == expected)
    }

    @Test("ArchiveStatus init(value:) defaults to failed for unknown string")
    func archiveStatusInitValueDefaultsToFailed() {
        let status = ArchiveStatus(value: "anything-else")
        #expect(status == .failed)
    }

    @Test("ArchiveStatus init(value:) defaults to failed for empty string")
    func archiveStatusInitValueDefaultsToFailedForEmpty() {
        let status = ArchiveStatus(value: "")
        #expect(status == .failed)
    }

    // MARK: - Archive Entity

    @Test("Archive equality with identical properties")
    func archiveEquality() {
        let id = UUID()
        let date = Date()
        let url = URL(string: "https://example.com/archive.mp4")!

        let archive1 = Archive(
            id: id, name: "Test", createdAt: date,
            status: .available, url: url, size: 1024, duration: 60)
        let archive2 = Archive(
            id: id, name: "Test", createdAt: date,
            status: .available, url: url, size: 1024, duration: 60)

        #expect(archive1 == archive2)
    }

    @Test("Archive inequality with different id")
    func archiveInequalityById() {
        let date = Date()
        let archive1 = Archive(
            id: UUID(), name: "Test", createdAt: date,
            status: .available, url: nil, size: 0, duration: 0)
        let archive2 = Archive(
            id: UUID(), name: "Test", createdAt: date,
            status: .available, url: nil, size: 0, duration: 0)

        #expect(archive1 != archive2)
    }

    @Test("Archive inequality with different status")
    func archiveInequalityByStatus() {
        let id = UUID()
        let date = Date()
        let archive1 = Archive(
            id: id, name: "Test", createdAt: date,
            status: .available, url: nil, size: 0, duration: 0)
        let archive2 = Archive(
            id: id, name: "Test", createdAt: date,
            status: .stopped, url: nil, size: 0, duration: 0)

        #expect(archive1 != archive2)
    }

    @Test("Archive with nil URL")
    func archiveWithNilURL() {
        let archive = Archive(
            id: UUID(), name: "Test", createdAt: Date(),
            status: .stopped, url: nil, size: 0, duration: 0)

        #expect(archive.url == nil)
    }

    @Test("Archive with URL")
    func archiveWithURL() {
        let url = URL(string: "https://example.com/recording.mp4")!
        let archive = Archive(
            id: UUID(), name: "Test", createdAt: Date(),
            status: .available, url: url, size: 2048, duration: 120)

        #expect(archive.url == url)
        #expect(archive.size == 2048)
        #expect(archive.duration == 120)
    }
}
