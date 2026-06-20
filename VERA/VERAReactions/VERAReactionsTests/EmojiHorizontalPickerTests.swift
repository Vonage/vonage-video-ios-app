//
//  Created by Vonage on 19/06/2026.
//

import Combine
import SwiftUI
import Testing

@testable import VERAReactions

#if os(macOS)
    import AppKit
    private typealias HostingController<Content: View> = NSHostingController<Content>
#else
    import UIKit
    private typealias HostingController<Content: View> = UIHostingController<Content>
#endif

@Suite("Emoji horizontal picker tests")
@MainActor
struct EmojiHorizontalPickerTests {

    @Test("Factory creates horizontal picker with new view model")
    func factoryCreatesHorizontalPickerWithNewViewModel() {
        let useCase = MockSendReactionUseCase()
        let sut = ReactionsFactory(
            reactionsRepository: ReactionsRepositorySpy(),
            sendReactionUseCase: useCase
        )

        let result = sut.makeEmojiHorizontalPickerContainer()

        #expect(result.viewModel.configuration == .default)
        host(result.view)
    }

    @Test("Factory creates emoji button using existing view model")
    func factoryCreatesEmojiButtonUsingExistingViewModel() {
        let sut = ReactionsFactory(
            reactionsRepository: ReactionsRepositorySpy(),
            sendReactionUseCase: MockSendReactionUseCase()
        )
        let viewModel = EmojiButtonContainerViewModel(
            sendReactionUseCase: MockSendReactionUseCase()
        )

        let view = sut.makeEmojiButtonContainer(viewModel: viewModel)

        host(view)
    }

    @Test("Factory creates emoji picker with new view model")
    func factoryCreatesEmojiPickerWithNewViewModel() {
        let useCase = MockSendReactionUseCase()
        let sut = ReactionsFactory(
            reactionsRepository: ReactionsRepositorySpy(),
            sendReactionUseCase: useCase
        )

        let result = sut.makeEmojiPickerContainer()

        #expect(result.viewModel.configuration == .default)
        host(result.view)
    }

    @Test("Factory creates horizontal picker using existing view model")
    func factoryCreatesHorizontalPickerUsingExistingViewModel() {
        let sut = ReactionsFactory(
            reactionsRepository: ReactionsRepositorySpy(),
            sendReactionUseCase: MockSendReactionUseCase()
        )
        let viewModel = EmojiPickerContainerViewModel(
            sendReactionUseCase: MockSendReactionUseCase()
        )

        let view = sut.makeEmojiHorizontalPickerContainer(viewModel: viewModel)

        host(view)
    }

    @Test("Factory creates emoji button with configured view model")
    func factoryCreatesEmojiButtonWithConfiguredViewModel() {
        let useCase = MockSendReactionUseCase()
        let configuration = EmojiPickerConfiguration(
            emojis: [UIEmojiReaction(emoji: "🎉", name: "Party")]
        )
        let sut = ReactionsFactory(
            reactionsRepository: ReactionsRepositorySpy(),
            sendReactionUseCase: useCase
        )

        let result = sut.makeEmojiButton(configuration: configuration)

        _ = result.viewModel
        host(result.view)
    }

    @Test("Factory creates floating emojis overlay with repository")
    func factoryCreatesFloatingEmojisOverlayWithRepository() {
        let repository = ReactionsRepositorySpy()
        let sut = ReactionsFactory(
            reactionsRepository: repository,
            sendReactionUseCase: MockSendReactionUseCase()
        )

        let result = sut.makeFloatingEmojisOverlay()

        #expect(result.viewModel.floatingEmojis.isEmpty)
        host(result.view)
    }

    @Test("Factory exposes reactions repository")
    func factoryExposesReactionsRepository() {
        let repository = ReactionsRepositorySpy()
        let sut = ReactionsFactory(
            reactionsRepository: repository,
            sendReactionUseCase: MockSendReactionUseCase()
        )

        #expect(sut.repository as? ReactionsRepositorySpy === repository)
    }

    @Test("Horizontal picker container sends selected reaction through view model")
    func horizontalPickerContainerSendsSelectedReactionThroughViewModel() {
        let useCase = MockSendReactionUseCase()
        let viewModel = EmojiPickerContainerViewModel(
            sendReactionUseCase: useCase
        )
        let sut = EmojiHorizontalPickerViewContainer(viewModel: viewModel)
        let emoji = UIEmojiReaction(emoji: "🚀", name: "Rocket")

        host(sut)
        sut.select(emoji)

        #expect(useCase.sentEmojis == ["🚀"])
    }

    @Test("Horizontal picker body renders configured emojis")
    func horizontalPickerBodyRendersConfiguredEmojis() {
        let emojis = [
            UIEmojiReaction(emoji: "👍", name: "Thumbs up"),
            UIEmojiReaction(emoji: "🎉", name: "Party"),
        ]
        let sut = EmojiHorizontalPickerView(
            emojis: emojis,
            showsHighlight: false
        ) { _ in }

        host(sut)
    }

    @Test("Horizontal picker supports custom highlight color")
    func horizontalPickerSupportsCustomHighlightColor() {
        let sut = EmojiHorizontalPickerView(
            emojis: [UIEmojiReaction(emoji: "🎉", name: "Party")],
            highlightColor: .black
        ) { _ in }

        host(sut)
    }

    @Test("Horizontal picker can disable scroll affordance")
    func horizontalPickerCanDisableScrollAffordance() {
        let sut = EmojiHorizontalPickerView(
            emojis: UIEmojiReaction.defaultEmojis,
            showsScrollAffordance: false
        ) { _ in }

        host(sut)
    }

    @Test("Horizontal scroll affordance state has no fades without overflow")
    func horizontalScrollAffordanceStateHasNoFadesWithoutOverflow() {
        let state = HorizontalScrollAffordanceMaskState.resolve(
            isEnabled: true,
            visibleWidth: 240,
            contentWidth: 240,
            scrollOffset: 0,
            fadeWidth: 32,
            tolerance: 1
        )

        #expect(state.leadingFade == false)
        #expect(state.trailingFade == false)
        #expect(state.leadingStop == CGFloat(32) / CGFloat(240))
        #expect(state.trailingStop == 1 - CGFloat(32) / CGFloat(240))
    }

    @Test("Horizontal scroll affordance state shows trailing fade at start")
    func horizontalScrollAffordanceStateShowsTrailingFadeAtStart() {
        let state = HorizontalScrollAffordanceMaskState.resolve(
            isEnabled: true,
            visibleWidth: 240,
            contentWidth: 400,
            scrollOffset: 0,
            fadeWidth: 32,
            tolerance: 1
        )

        #expect(state.leadingFade == false)
        #expect(state.trailingFade == true)
    }

    @Test("Horizontal scroll affordance state shows both fades in middle")
    func horizontalScrollAffordanceStateShowsBothFadesInMiddle() {
        let state = HorizontalScrollAffordanceMaskState.resolve(
            isEnabled: true,
            visibleWidth: 240,
            contentWidth: 400,
            scrollOffset: 80,
            fadeWidth: 32,
            tolerance: 1
        )

        #expect(state.leadingFade == true)
        #expect(state.trailingFade == true)
    }

    @Test("Horizontal scroll affordance state shows leading fade at end")
    func horizontalScrollAffordanceStateShowsLeadingFadeAtEnd() {
        let state = HorizontalScrollAffordanceMaskState.resolve(
            isEnabled: true,
            visibleWidth: 240,
            contentWidth: 400,
            scrollOffset: 160,
            fadeWidth: 32,
            tolerance: 1
        )

        #expect(state.leadingFade == true)
        #expect(state.trailingFade == false)
    }

    @Test("Horizontal scroll affordance state disables fades")
    func horizontalScrollAffordanceStateDisablesFades() {
        let state = HorizontalScrollAffordanceMaskState.resolve(
            isEnabled: false,
            visibleWidth: 240,
            contentWidth: 400,
            scrollOffset: 80,
            fadeWidth: 32,
            tolerance: 1
        )

        #expect(state.leadingFade == false)
        #expect(state.trailingFade == false)
    }

    @Test("Horizontal scroll affordance state handles zero visible width")
    func horizontalScrollAffordanceStateHandlesZeroVisibleWidth() {
        let state = HorizontalScrollAffordanceMaskState.resolve(
            isEnabled: true,
            visibleWidth: 0,
            contentWidth: 400,
            scrollOffset: 0,
            fadeWidth: 32,
            tolerance: 1
        )

        #expect(state.leadingStop == 0)
        #expect(state.trailingStop == 1)
    }

    @Test("Horizontal picker content calls selection action")
    func horizontalPickerContentCallsSelectionAction() {
        let emoji = UIEmojiReaction(emoji: "👏", name: "Clap")
        var selectedEmoji: UIEmojiReaction?
        let sut = EmojiHorizontalPickerContent(
            emojis: [emoji],
            showsHighlight: false,
            highlightDuration: 0,
            highlightColor: .white,
            onEmojiSelected: { selectedEmoji = $0 }
        )

        host(sut)
        sut.handleEmojiTap(emoji)

        #expect(selectedEmoji == emoji)
    }

    @Test("Horizontal picker content supports highlight on selection")
    func horizontalPickerContentSupportsHighlightOnSelection() {
        let emoji = UIEmojiReaction(emoji: "👍", name: "Thumbs up")
        var selectedEmoji: UIEmojiReaction?
        let sut = EmojiHorizontalPickerContent(
            emojis: [emoji],
            showsHighlight: true,
            highlightDuration: 0,
            highlightColor: .white,
            onEmojiSelected: { selectedEmoji = $0 }
        )

        host(sut)
        sut.handleEmojiTap(emoji)

        #expect(selectedEmoji == emoji)
    }

    @discardableResult
    private func host<V: View>(_ view: V) -> HostingController<V> {
        let controller = HostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 160)
        #if os(macOS)
            controller.view.layoutSubtreeIfNeeded()
        #else
            controller.view.layoutIfNeeded()
        #endif
        return controller
    }
}

private final class ReactionsRepositorySpy: ReactionsRepository, @unchecked Sendable {
    private let subject = PassthroughSubject<EmojiReaction, Never>()

    var reactionReceived: AnyPublisher<EmojiReaction, Never> {
        subject.eraseToAnyPublisher()
    }

    func addReaction(_ reaction: EmojiReaction) async {
        subject.send(reaction)
    }
}
