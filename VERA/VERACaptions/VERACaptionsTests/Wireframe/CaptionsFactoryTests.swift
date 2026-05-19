//
//  Created by Vonage on 20/02/2026.
//

import Combine
import Foundation
import Testing
import VERADomain

@testable import VERACaptions

@Suite("CaptionsFactory Tests")
@MainActor
struct CaptionsFactoryTests {

    @Test("makeCaptionsButton returns a configured view model")
    func makeCaptionsButtonReturnsViewModel() {
        let sut = makeSUT()

        let (_, viewModel) = sut.makeCaptionsButton()

        #expect(viewModel.state == .disabled)
    }

    @Test("makeCaptionsButton view model can be set up without crash")
    func makeCaptionsButtonSetup() {
        let sut = makeSUT()

        let (_, viewModel) = sut.makeCaptionsButton()
        viewModel.setup()

        #expect(viewModel.state == .disabled)
    }

    @Test("makeCaptionsView returns a view model with empty captions")
    func makeCaptionsViewReturnsViewModel() {
        let sut = makeSUT()

        let (_, viewModel) = sut.makeCaptionsView()

        #expect(viewModel.captions.isEmpty)
    }

    @Test("repository returns the injected repository")
    func repositoryAccessor() async throws {
        let repository = DefaultCaptionsRepository()
        let sut = CaptionsFactory(
            captionsActivationDataSource: MockCaptionsActivationDataSource(),
            captionsStatusDataSource: DefaultCaptionsStatusDataSource(),
            captionsRepository: repository,
            sessionKeyProvider: DefaultSessionKeyHolder()
        )

        let caption = CaptionItem(id: "1", speakerName: "Alice", text: "Hi")
        await sut.repository.updateCaptions([caption])

        var received: [CaptionItem] = []
        let cancellable = sut.repository.captionsReceived.sink { received = $0 }
        _ = cancellable

        #expect(received.count == 1)
        #expect(received.first?.id == "1")
    }

    // MARK: - Helpers

    private func makeSUT() -> CaptionsFactory {
        CaptionsFactory(
            captionsActivationDataSource: MockCaptionsActivationDataSource(),
            captionsStatusDataSource: DefaultCaptionsStatusDataSource(),
            captionsRepository: DefaultCaptionsRepository(),
            sessionKeyProvider: DefaultSessionKeyHolder()
        )
    }
}

// MARK: - Test Doubles

private final class MockCaptionsActivationDataSource: CaptionsActivationDataSource, @unchecked Sendable {
    func enableCaptions(
        _ request: EnableCaptionsDataSourceRequest
    ) async throws -> EnableCaptionsDataSourceResponse {
        .init(captionsId: "mock-id")
    }
}
