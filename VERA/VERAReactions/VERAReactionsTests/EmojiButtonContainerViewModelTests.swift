//
//  Created by Vonage on 11/2/26.
//

import Foundation
import Testing

@testable import VERAReactions

/// Tests for `EmojiButtonContainerViewModel`.
@Suite("EmojiButtonContainerViewModel Tests")
struct EmojiButtonContainerViewModelTests {

    // MARK: - Mock Dependencies

    /// A mock implementation of `SendReactionUseCase` for testing.
    private struct MockSendReactionUseCase: SendReactionUseCase {
        var shouldThrow: Bool = false

        func callAsFunction(_ emoji: String) throws {
            if shouldThrow {
                throw NSError(domain: "Test", code: 1, userInfo: nil)
            }
        }
    }

    // MARK: - Initial State Tests

    @Test("Initial state has picker hidden")
    func initialStateHasPickerHidden() {
        let sut = makeSUT()

        #expect(sut.isPickerVisible == false)
    }

    @Test("Initial state creates picker ViewModel with configuration")
    func initialStateCreatesPickerViewModel() {
        let configuration = EmojiPickerConfiguration.default
        let sut = makeSUT(configuration: configuration)

        #expect(sut.pickerViewModel.configuration.emojis == configuration.emojis)
    }

    // MARK: - Toggle Picker Tests

    @Test("Toggle picker shows picker when hidden")
    func togglePickerShowsPickerWhenHidden() {
        let sut = makeSUT()

        sut.togglePicker()

        #expect(sut.isPickerVisible == true)
    }

    @Test("Toggle picker hides picker when visible")
    func togglePickerHidesPickerWhenVisible() {
        let sut = makeSUT()

        sut.togglePicker()
        sut.togglePicker()

        #expect(sut.isPickerVisible == false)
    }

    @Test("Double toggle returns to initial state")
    func doubleToggleReturnsToInitialState() {
        let sut = makeSUT()

        let initialState = sut.isPickerVisible
        sut.togglePicker()
        sut.togglePicker()

        #expect(sut.isPickerVisible == initialState)
    }

    // MARK: - Show/Hide Picker Tests

    @Test("Show picker sets visibility to true")
    func showPickerSetsVisibilityToTrue() {
        let sut = makeSUT()

        sut.showPicker()

        #expect(sut.isPickerVisible == true)
    }

    @Test("Hide picker sets visibility to false")
    func hidePickerSetsVisibilityToFalse() {
        let sut = makeSUT()

        sut.showPicker()
        sut.hidePicker()

        #expect(sut.isPickerVisible == false)
    }

    @Test("Hide picker when already hidden remains false")
    func hidePickerWhenAlreadyHiddenRemainsFalse() {
        let sut = makeSUT()

        sut.hidePicker()

        #expect(sut.isPickerVisible == false)
    }

    // MARK: - Picker ViewModel Integration Tests

    @Test("hidePicker hides picker after showing")
    func pickerViewModelOnDismissHidesPicker() {
        let sut = makeSUT()

        sut.showPicker()
        sut.hidePicker()

        #expect(sut.isPickerVisible == false)
    }

    @Test("Picker ViewModel is reused across toggle cycles")
    func pickerViewModelIsReusedAcrossToggleCycles() {
        let sut = makeSUT()

        let firstViewModel = sut.pickerViewModel
        sut.togglePicker()
        sut.togglePicker()
        let secondViewModel = sut.pickerViewModel

        #expect(firstViewModel === secondViewModel)
    }

    // MARK: - Test Helpers

    private func makeSUT(configuration: EmojiPickerConfiguration = .default) -> EmojiButtonContainerViewModel {
        return .init(sendReactionUseCase: MockSendReactionUseCase(), configuration: configuration)
    }

}
