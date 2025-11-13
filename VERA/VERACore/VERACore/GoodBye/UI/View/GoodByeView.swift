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
            Banner()
                .frame(height: 70)
                .padding(.horizontal, 8)
            Group {
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
            .frame(maxHeight: .infinity)
            .padding(10)
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
        HStack(alignment: .center, spacing: 20) {
            GoodByeMessage(
                onReenter: onReenter,
                onReturnToLanding: onReturnToLanding
            )
            .frame(maxWidth: .infinity)
            .padding(.bottom, 40)

            ArchiveList(archives: archives)
                .frame(maxWidth: .infinity)
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
        VStack(alignment: .center, spacing: 20) {
            GoodByeMessage(
                onReenter: onReenter,
                onReturnToLanding: onReturnToLanding
            )
            .frame(maxWidth: .infinity)
            .padding(.bottom, 40)
            .padding(.horizontal, 20)

            ArchiveList(archives: archives)
                .frame(maxWidth: .infinity)
            Spacer()
        }
    }
}

#Preview {
    GoodByeView(archives: []) {
    } onReturnToLanding: {
    }
}
