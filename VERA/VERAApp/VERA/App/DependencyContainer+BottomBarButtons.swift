//
//  Created by Vonage on 22/1/26.
//

import Foundation
import VERACommonUI
import VERACore

#if CHAT_ENABLED
    import VERAChat
    import VERAVonageChatPlugin
#endif

#if ARCHIVING_ENABLED
    import VERAArchiving
    import VERAVonageArchivingPlugin
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
                label: state.archivingState == .recording
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
}
