//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

public struct GoodByeView<ContentView: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    private let additionalContentView: () -> ContentView
    public let onReenter: () -> Void
    public let onReturnToLanding: () -> Void

    public init(
        @ViewBuilder additionalContentView: @escaping () -> ContentView,
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) {
        self.additionalContentView = additionalContentView
        self.onReenter = onReenter
        self.onReturnToLanding = onReturnToLanding
    }

    public var body: some View {
        VStack(spacing: 0) {
            if verticalSizeClass == .compact {
                HorizontalGoodByeContentView(
                    additionalContentView: additionalContentView,
                    onReenter: onReenter,
                    onReturnToLanding: onReturnToLanding)
            } else if horizontalSizeClass == .compact {
                VerticalGoodByeContentView(
                    additionalContentView: additionalContentView,
                    onReenter: onReenter,
                    onReturnToLanding: onReturnToLanding)
            } else {
                HorizontalGoodByeContentView(
                    additionalContentView: additionalContentView,
                    onReenter: onReenter,
                    onReturnToLanding: onReturnToLanding)
            }
        }
        .background(VERACommonUIAsset.SemanticColors.surface.swiftUIColor)
    }
}

public struct HorizontalGoodByeContentView<ContentView: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass

    private let additionalContentView: () -> ContentView
    public let onReenter: () -> Void
    public let onReturnToLanding: () -> Void

    public init(
        @ViewBuilder additionalContentView: @escaping () -> ContentView,
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) {
        self.additionalContentView = additionalContentView
        self.onReenter = onReenter
        self.onReturnToLanding = onReturnToLanding
    }

    public var body: some View {
        HorizontalContentView(showFooter: verticalSizeClass == .regular) {
            GoodByeMessage()
                .padding(.bottom, 40)
                .padding(.horizontal, 20)
        } rightSide: {
            VStack(alignment: .center, spacing: 0) {
                CardView {
                    VStack(alignment: .leading) {
                        RejoinTheRoomText()
                        ReenterRoomButton(onReenter: onReenter)
                        GoToLandingPageButton(onReturnToLanding: onReturnToLanding)
                    }
                }
                additionalContentView()
                    .padding(.top)
            }
        }
    }
}

public struct VerticalGoodByeContentView<ContentView: View>: View {

    private let additionalContentView: () -> ContentView
    public let onReenter: () -> Void
    public let onReturnToLanding: () -> Void

    public init(
        @ViewBuilder additionalContentView: @escaping () -> ContentView,
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) {
        self.additionalContentView = additionalContentView
        self.onReenter = onReenter
        self.onReturnToLanding = onReturnToLanding
    }

    public var body: some View {
        VerticalContentView {
            GoodByeMessage(showSubtitle: false)
                .padding()
                .padding(.horizontal)
            RejoinTheRoomText()
                .padding(.horizontal)
                .padding(.top)
                .padding(.horizontal)
            ReenterRoomButton(onReenter: onReenter)
                .padding()
                .padding(.horizontal)
            GoToLandingPageButton(onReturnToLanding: onReturnToLanding)
                .padding(.horizontal)
                .padding(.horizontal)
        } bottomSide: {
            additionalContentView()
                .padding(.top)
        }
    }
}

#Preview {
    GoodByeView {
    } onReenter: {
    } onReturnToLanding: {
    }
}
