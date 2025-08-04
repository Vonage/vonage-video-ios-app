//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

public struct GoodByeView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    public let onReenter: () -> Void
    public let onReturnToLanding: () -> Void

    public init(
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) {
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
                        onReenter: onReenter,
                        onReturnToLanding: onReturnToLanding)
                } else if horizontalSizeClass == .compact {
                    VerticalGoodByeContentView(
                        onReenter: onReenter,
                        onReturnToLanding: onReturnToLanding)
                } else {
                    HorizontalGoodByeContentView(
                        onReenter: onReenter,
                        onReturnToLanding: onReturnToLanding)
                }
            }
            .frame(maxHeight: .infinity)
            .padding(10)
        }
        .background(.uiSystemBackground)
    }
}

public struct HorizontalGoodByeContentView: View {

    public let onReenter: () -> Void
    public let onReturnToLanding: () -> Void

    public init(
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) {
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

            ArchiveList()
                .frame(maxWidth: .infinity)
        }
    }
}

public struct VerticalGoodByeContentView: View {

    public let onReenter: () -> Void
    public let onReturnToLanding: () -> Void

    public init(
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) {
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

            ArchiveList()
                .frame(maxWidth: .infinity)
            Spacer()
        }
    }
}

#Preview {
    GoodByeView {
    } onReturnToLanding: {
    }
}
