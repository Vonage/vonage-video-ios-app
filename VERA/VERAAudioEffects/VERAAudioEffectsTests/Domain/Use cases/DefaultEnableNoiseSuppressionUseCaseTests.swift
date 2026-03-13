//
//  Created by Vonage on 13/3/26.
//

import Combine
import SwiftUI
import Testing
import VERAAudioEffects
import VERADomain

@Suite("DefaultEnableNoiseSuppressionUseCase tests")
struct DefaultEnableNoiseSuppressionUseCaseTests {

    @Test("Calling use case enables noise suppression on publisher")
    func enablesNoiseSuppressionOnPublisher() async throws {
        let publisher = NoiseSuppressionPublisherSpy()
        let sut = makeSUT()

        sut(publisher: publisher)

        #expect(publisher.setNoiseSuppression_callCount == 1)
    }

    @Test("Calling use case sets state to enabled on data source")
    func setsStateToEnabledOnDataSource() async throws {
        let publisher = NoiseSuppressionPublisherSpy()
        let dataSource = NoiseSuppressionStatusDataSourceSpy()
        let sut = makeSUT(dataSource: dataSource)

        sut(publisher: publisher)

        #expect(dataSource.setState_callCount == 1)
        #expect(dataSource.setState_lastValue == .enabled)
    }

    @Test("Calling use case enables noise suppression before setting state")
    func enablesNoiseSuppressionBeforeSettingState() async throws {
        let publisher = NoiseSuppressionPublisherSpy()
        let dataSource = NoiseSuppressionStatusDataSourceSpy()
        let sut = makeSUT(dataSource: dataSource)

        sut(publisher: publisher)

        #expect(publisher.setNoiseSuppression_callCount == 1)
        #expect(dataSource.setState_callCount == 1)
    }

    @Test("When publisher throws error, state is not updated")
    func whenPublisherThrowsError_stateIsNotUpdated() async throws {
        let shouldThrowError = true
        let publisher = NoiseSuppressionPublisherSpy(shouldThrowError: shouldThrowError)
        let dataSource = NoiseSuppressionStatusDataSourceSpy(shouldThrowError: shouldThrowError)
        let sut = makeSUT(dataSource: dataSource)

        sut(publisher: publisher)

        #expect(publisher.setNoiseSuppression_callCount == 0)
        #expect(dataSource.setState_callCount == 0)
    }

    @Test("Calling use case multiple times enables noise suppression each time")
    func multipleCallsEnablesNoiseSuppressionEachTime() async throws {
        let publisher = NoiseSuppressionPublisherSpy()
        let dataSource = NoiseSuppressionStatusDataSourceSpy()
        let sut = makeSUT(dataSource: dataSource)

        sut(publisher: publisher)
        sut(publisher: publisher)
        sut(publisher: publisher)

        #expect(publisher.setNoiseSuppression_callCount == 3)
        #expect(dataSource.setState_callCount == 3)
        #expect(dataSource.setState_lastValue == .enabled)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        dataSource: NoiseSuppressionStatusDataSource = NoiseSuppressionStatusDataSourceSpy()
    ) -> DefaultEnableNoiseSuppressionUseCase {
        DefaultEnableNoiseSuppressionUseCase(
            noiseSuppressionStatusDataSource: dataSource
        )
    }
}
