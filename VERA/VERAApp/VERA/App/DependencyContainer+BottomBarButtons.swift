//
//  Created by Vonage on 22/1/26.
//

import Foundation
import VERACommonUI
import VERACore
import VERADomain

#if CHAT_ENABLED
    import VERAChat
    import VERAVonageChatPlugin
#endif

#if ARCHIVING_ENABLED
    import VERAArchiving
    import VERAVonageArchivingPlugin
#endif

#if BACKGROUND_EFFECTS_ENABLED
    import VERABackgroundEffects
#endif

#if CAPTIONS_ENABLED
    import VERACaptions
#endif

#if REACTIONS_ENABLED
    import SwiftUI
    import VERAReactions
#endif

#if SCREEN_SHARE_ENABLED
    import SwiftUI
    import VERAScreenShare
#endif

extension DependencyContainer {
    #if ARCHIVING_ENABLED
        func mapToArchiveBottomBarButton(
            _ archiveButtonViewModel: ArchiveButtonViewModel,
            _ state: MeetingRoomButtonsState
        ) -> BottomBarButton {
            let archiveFactory = archivingFactory
            let archiveButton = archiveFactory.makeArchivingButton(viewModel: archiveButtonViewModel)
            return .init(
                label: state.archivingState.isArchiving
                    ? String(localized: "Stop Recording") : String(localized: "Start Recording"),
                image: VERACommonUIAsset.Images.radioChecked2Line.swiftUIImage,
                onTap: archiveButtonViewModel.onTap,
                content: {
                    archiveButton
                })
        }
    #endif

    #if CHAT_ENABLED
        func mapToChatBottomBarButton(onShowChat: @escaping () -> Void) -> BottomBarButton {
            return .init(
                label: "Chat",
                image: VERACommonUIAsset.Images.chat2Solid.swiftUIImage,
                onTap: onShowChat,
                content: {
                    ChatBadgeButton(
                        unreadMessagesCount: 0,
                        onShowChat: onShowChat)
                })
        }
    #endif

    #if BACKGROUND_EFFECTS_ENABLED
        func makeBackgroundEffectsButton(
            _ viewModel: BackgroundBlurButtonViewModel
        ) -> BottomBarButton {
            let button = backgroundBlurFactory.makeMeetingBlurButton(viewModel: viewModel)
            return .init(
                label: String(localized: "Blur"),
                image: viewModel.currentBlurLevel.image,
                onTap: {
                    viewModel.onTap()
                },
                content: {
                    button
                })
        }
    #endif

    #if CAPTIONS_ENABLED
        func makeCaptionsButton(
            _ viewModel: CaptionsButtonViewModel
        ) -> BottomBarButton {
            let button = captionsFactory.makeCaptionsButton(viewModel: viewModel)
            return .init(
                label: String(localized: "Captions"),
                image: viewModel.state.captionsEnabled
                    ? VERACommonUIAsset.Images.closedCaptioningOffSolid.swiftUIImage
                    : VERACommonUIAsset.Images.closedCaptioningSolid.swiftUIImage,
                onTap: {
                    viewModel.onTap()
                },
                content: {
                    button
                })
        }
    #endif

    #if REACTIONS_ENABLED
        func mapToReactionsBottomBarButton(
            _ viewModel: EmojiButtonContainerViewModel,
            onShowPicker: @escaping () -> Void
        ) -> BottomBarButton {
            let emojiButtonContainer = reactionsFactory.makeEmojiButtonContainer(viewModel: viewModel)
            return .init(
                label: String(localized: "Reactions"),
                image: VERACommonUIAsset.Images.emojiSolid.swiftUIImage,
                onTap: onShowPicker,
                content: {
                    emojiButtonContainer
                }
            )
        }
    #endif

    #if SCREEN_SHARE_ENABLED
        @MainActor
        func makeScreenShareButton() -> BottomBarButton {
            let button = ScreenShareFactory.make()
            return .init(
                label: String(localized: "Share Screen"),
                image: Image(systemName: "rectangle.on.rectangle"),
                onTap: {},
                content: {
                    button
                })
        }
    #endif
}
