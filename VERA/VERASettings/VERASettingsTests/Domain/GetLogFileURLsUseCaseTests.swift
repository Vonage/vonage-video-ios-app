//
//  Created by Vonage on 23/06/2026.
//

import Foundation
import Testing

@testable import VERASettings

@Suite("GetLogFileURLsUseCase Tests")
struct GetLogFileURLsUseCaseTests {

    // MARK: - NullLogFileURLDataSource

    @Test("NullLogFileURLDataSource always returns empty array")
    func nullDataSourceReturnsEmpty() {
        let dataSource = NullLogFileURLDataSource()

        #expect(dataSource.getLogFileURLs().isEmpty)
    }

    // MARK: - SDKLogFileURLDataSource

    @Test("SDKLogFileURLDataSource returns URLs from provider closure")
    func sdkDataSourceReturnsFromProvider() {
        let expectedURLs = [URL(fileURLWithPath: "/tmp/log1.log"), URL(fileURLWithPath: "/tmp/log2.log")]
        let dataSource = SDKLogFileURLDataSource(provider: { expectedURLs })

        #expect(dataSource.getLogFileURLs() == expectedURLs)
    }

    @Test("SDKLogFileURLDataSource returns empty when provider returns empty")
    func sdkDataSourceReturnsEmptyFromProvider() {
        let dataSource = SDKLogFileURLDataSource(provider: { [] })

        #expect(dataSource.getLogFileURLs().isEmpty)
    }

    // MARK: - DefaultGetLogFileURLsUseCase

    @Test("DefaultGetLogFileURLsUseCase delegates to data source")
    func defaultUseCaseDelegatesToDataSource() {
        let expectedURLs = [URL(fileURLWithPath: "/tmp/sdk.log")]
        let dataSource = SDKLogFileURLDataSource(provider: { expectedURLs })
        let useCase = DefaultGetLogFileURLsUseCase(dataSource: dataSource)

        #expect(useCase() == expectedURLs)
    }

    @Test("DefaultGetLogFileURLsUseCase with null data source returns empty")
    func defaultUseCaseWithNullDataSourceReturnsEmpty() {
        let useCase = DefaultGetLogFileURLsUseCase(dataSource: NullLogFileURLDataSource())

        #expect(useCase().isEmpty)
    }

    @Test("callAsFunction invocation syntax works")
    func callAsFunctionSyntaxWorks() {
        let expectedURLs = [URL(fileURLWithPath: "/tmp/test.log")]
        let dataSource = SDKLogFileURLDataSource(provider: { expectedURLs })
        let useCase: GetLogFileURLsUseCase = DefaultGetLogFileURLsUseCase(dataSource: dataSource)

        let result = useCase()

        #expect(result == expectedURLs)
    }
}
