//
//  Created by Vonage on 13/3/26.
//

import Combine
import Testing
import VERAAudioEffects
import VERADomain

@Suite("DefaultDisableNoiseSuppressionUseCase tests")
struct DefaultDisableNoiseSuppressionUseCaseTests {

    @Test("Calling use case sets state to disabled")
    func setsStateToDisabled() async throws {
        let dataSource = NoiseSuppressionStatusDataSourceSpy()
        let sut = makeSUT(dataSource: dataSource)

        sut()

        #expect(dataSource.setState_callCount == 1)
        #expect(dataSource.setState_lastValue == .disabled)
    }

    @Test("Calling use case multiple times sets state to disabled each time")
    func multipleCallsSetsStateMultipleTimes() async throws {
        let dataSource = NoiseSuppressionStatusDataSourceSpy()
        let sut = makeSUT(dataSource: dataSource)

        sut()
        sut()
        sut()

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
