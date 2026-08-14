//
//  Created by Vonage on 8/6/26.
//

import Foundation
import Testing
import VERACore
import VERADomain
import VERAE2E
import VERAVonage

@testable import VERA
@testable import VERAMeetingRoomSDK

@Suite("App dependency provider tests")
struct AppDependencyProvidersTests {

    @Test("HTTP provider returns URL session client when E2E is disabled")
    func httpProviderReturnsURLSessionClientWhenE2EIsDisabled() {
        let sut = AppHTTPClientProvider(isE2EEnabled: false)

        let client = sut()

        #expect(client is URLSessionHTTPClient)
    }

    @Test("HTTP provider returns E2E client when E2E is enabled")
    func httpProviderReturnsE2EClientWhenE2EIsEnabled() {
        let sut = AppHTTPClientProvider(isE2EEnabled: true)

        let client = sut()

        #expect(client is E2EHTTPClient)
    }

    @Test("Dependency container exposes injected HTTP client")
    func dependencyContainerExposesInjectedHTTPClient() {
        let client = E2EHTTPClient(interceptor: HTTPClientInterceptorSpy())

        #if OKTA_ENABLED
            let sut = DependencyContainer(
                httpClient: client,
                e2eAuthManager: E2EAuthStateManager())
        #else
            let sut = DependencyContainer(httpClient: client)
        #endif

        #expect((sut.httpClient as? E2EHTTPClient) === client)
    }

    @Test("Shared meeting room HTTP client factory returns injected HTTP client")
    func sharedMeetingRoomHTTPClientFactoryReturnsInjectedHTTPClient() {
        let client = E2EHTTPClient(interceptor: HTTPClientInterceptorSpy())
        let sut = SharedMeetingRoomHTTPClientFactory(httpClient: client)

        let received = sut(HTTPClientContext(interceptor: HTTPClientInterceptorSpy()))

        #expect((received as? E2EHTTPClient) === client)
    }

    @Test("Shared E2E HTTP client lets goodbye archives load an archive")
    func sharedE2EHTTPClientLetsGoodbyeArchivesLoadArchive() async throws {
        let client = E2EHTTPClient(interceptor: HTTPClientInterceptorSpy())
        let dataSource = HTTPArchivesDataSource(
            baseURL: URL(string: "https://meet.example.com")!,
            httpClient: client,
            jsonDecoder: JSONDecoder())

        let archives = try await dataSource.getArchives(
            sessionKey: "e2e-session-key-\(UUID().uuidString.lowercased())")

        #expect(!archives.isEmpty)
        #expect(archives.first?.url != nil)
    }
}

private final class HTTPClientInterceptorSpy: HTTPClientInterceptor, @unchecked Sendable {
    func didSucceed(_ event: HTTPClientSuccessEvent) {}
    func didFail(_ event: HTTPClientFailureEvent) {}
}
