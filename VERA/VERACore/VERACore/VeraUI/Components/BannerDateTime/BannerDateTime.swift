//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

struct BannerDateTime: View {
    @State private var now: Date = .init()
    private let timer = Timer.publish(
        every: 60,
        on: .main,
        in: .common
    )
    .autoconnect()

    private static let usFormatter: DateFormatter = {
        let dataFormatter = DateFormatter()
        dataFormatter.dateFormat = String(localized: "h:mm a • EEE, MMM d", bundle: .veraCore)
        return dataFormatter
    }()

    var body: some View {
        Text(Self.usFormatter.string(from: now))
            .font(.title3)
            .foregroundStyle(.uiLabel.opacity(0.5))
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
            .onReceive(timer) { now = $0 }
    }
}

#Preview {
    BannerDateTime()
}
