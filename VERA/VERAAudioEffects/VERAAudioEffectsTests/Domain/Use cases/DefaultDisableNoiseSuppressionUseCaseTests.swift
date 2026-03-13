//
//  Created by Vonage on 13/3/26.
//

import Combine
import Testing
import VERAAudioEffects
import VERADomain

@Suite("DefaultDisableNoiseSuppressionUseCase tests")
struct DefaultDisableNoiseSuppressionUseCaseTests {

    @Test("Calling use case disables noise suppression on publisher")
    func disablesNoiseSuppressionOnPublisher() async throws {
        let publisher = NoiseSuppressionPublisherSpy()
        let sut = makeSUT()

        sut(publisher: publisher)

        #expect(publisher.removeAudioTransform_callCount == 1)
    }

    @Test("Calling use case sets state to disabled on data source")
    func setsStateToDisabledOnDataSource() async throws {
        let publisher = NoiseSuppressionPublisherSpy()
        let dataSource = NoiseSuppressionStatusDataSourceSpy()
        let sut = makeSUT(dataSource: dataSource)

        sut(publisher: publisher)

        #expect(dataSource.setState_callCount == 1)
        #expect(dataSource.setState_lastValue == .disabled)
    }

    @Test("Calling use case disables noise suppression before setting state")
    func disablesNoiseSuppressionBeforeSettingState() async throws {
        let publisher = NoiseSuppressionPublisherSpy()
        let dataSource = NoiseSuppressionStatusDataSourceSpy()
        let sut = makeSUT(dataSource: dataSource)

        sut(publisher: publisher)

        #expect(publisher.removeAudioTransform_callCount == 1)
        #expect(dataSource.setState_callCount == 1)
    }

    @Test("When publisher throws error, state is not updated")
    func whenPublisherThrowsError_stateIsNotUpdated() async throws {
        let shouldThrowError = true
        let publisher = NoiseSuppressionPublisherSpy(shouldThrowError: shouldThrowError)
        let dataSource = NoiseSuppressionStatusDataSourceSpy(shouldThrowError: shouldThrowError)
        let sut = makeSUT(dataSource: dataSource)

        sut(publisher: publisher)

        #expect(publisher.removeAudioTransform_callCount == 0)
        #expect(dataSource.setState_callCount == 0)
    }

    @Test("Calling use case multiple times disables noise suppression each time")
    func multipleCallsDisablesNoiseSuppressionEachTime() async throws {
        let publisher = NoiseSuppressionPublisherSpy()
        let dataSource = NoiseSuppressionStatusDataSourceSpy()
        let sut = makeSUT(dataSource: dataSource)

        sut(publisher: publisher)
        sut(publisher: publisher)
        sut(publisher: publisher)

        #expect(publisher.removeAudioTransform_callCount == 3)
        #expect(dataSource.setState_callCount == 3)
        #expect(dataSource.setState_lastValue == .disabled)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        dataSource: NoiseSuppressionStatusDataSource = NoiseSuppressionStatusDataSourceSpy()
    ) -> DefaultDisableNoiseSuppressionUseCase {
        DefaultDisableNoiseSuppressionUseCase(
            noiseSuppressionStatusDataSource: dataSource
        )
    }
}
