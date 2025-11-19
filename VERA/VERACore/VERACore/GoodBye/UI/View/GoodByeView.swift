//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

public struct GoodByeView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    public let archives: [ArchiveUIData]
    public let onReenter: () -> Void
    public let onReturnToLanding: () -> Void

    public init(
        archives: [ArchiveUIData],
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) {
        self.archives = archives
        self.onReenter = onReenter
        self.onReturnToLanding = onReturnToLanding
    }

    public var body: some View {
        VStack(spacing: 0) {
            if verticalSizeClass == .compact {
                HorizontalGoodByeContentView(
                    archives: archives,
                    onReenter: onReenter,
                    onReturnToLanding: onReturnToLanding)
            } else if horizontalSizeClass == .compact {
                VerticalGoodByeContentView(
                    archives: archives,
                    onReenter: onReenter,
                    onReturnToLanding: onReturnToLanding)
            } else {
                HorizontalGoodByeContentView(
                    archives: archives,
                    onReenter: onReenter,
                    onReturnToLanding: onReturnToLanding)
            }
        }
        .background(VERACommonUIAsset.Colors.uiSystemBackground.swiftUIColor)
    }
}

public struct HorizontalGoodByeContentView: View {

    public let archives: [ArchiveUIData]
    public let onReenter: () -> Void
    public let onReturnToLanding: () -> Void

    public init(
        archives: [ArchiveUIData],
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) {
        self.archives = archives
        self.onReenter = onReenter
        self.onReturnToLanding = onReturnToLanding
    }

    public var body: some View {
        HorizontalContentView {
            GoodByeMessage(
                onReenter: onReenter,
                onReturnToLanding: onReturnToLanding
            )
            .padding(.bottom, 40)
            .padding(.horizontal, 20)
        } rightSide: {
            ArchiveList(archives: archives)
                .padding()
        }
    }
}

public struct VerticalGoodByeContentView: View {

    public let archives: [ArchiveUIData]
    public let onReenter: () -> Void
    public let onReturnToLanding: () -> Void

    public init(
        archives: [ArchiveUIData],
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) {
        self.archives = archives
        self.onReenter = onReenter
        self.onReturnToLanding = onReturnToLanding
    }

    public var body: some View {
        VerticalContentView {
            GoodByeMessage(
                onReenter: onReenter,
                onReturnToLanding: onReturnToLanding
            )
            .padding(.horizontal)
            .padding()
        } bottomSide: {
            ArchiveList(archives: archives)
                .padding()
        }
    }
}

#Preview {
    GoodByeView(archives: []) {
    } onReturnToLanding: {
    }
}
