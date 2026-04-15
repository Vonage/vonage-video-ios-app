//
//  Created by Vonage on 16/1/26.
//

import SwiftUI

struct Pulsating<Content: View>: View {
    let pulseFraction: CGFloat
    let durationSeconds: Double
    let content: () -> Content

    @State private var isAnimating = false

    init(
        pulseFraction: CGFloat = 1.2,
        durationSeconds: Double = 1.0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.pulseFraction = pulseFraction
        self.durationSeconds = durationSeconds
        self.content = content
    }

    var body: some View {
        content()
            .scaleEffect(isAnimating ? pulseFraction : 1.0)
            .opacity(isAnimating ? 1.0 : 0.8)
            .animation(
                .easeInOut(duration: durationSeconds)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - View Extension

extension View {
    func pulsating(
        pulseFraction: CGFloat = 1.2,
        durationSeconds: Double = 1.0
    ) -> some View {
        Pulsating(
            pulseFraction: pulseFraction,
            durationSeconds: durationSeconds
        ) {
            self
        }
    }
}

#Preview("Multiple Elements") {
    HStack(spacing: 30) {
        Circle()
            .fill(.red)
            .frame(width: 30, height: 30)
            .pulsating(pulseFraction: 1.1)

        Image(systemName: "record.circle")
            .resizable()
            .frame(width: 30, height: 30)
            .foregroundStyle(.red)
            .pulsating(pulseFraction: 1.1, durationSeconds: 0.6)
    }
    .padding()
}

#Preview("Text Pulsating") {
    VStack(spacing: 40) {
        Text("Recording...")
            .font(.title)
            .fontWeight(.bold)
            .foregroundStyle(.red)
            .pulsating()

        Text("LIVE")
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.red)
            )
            .foregroundStyle(.white)
            .pulsating(pulseFraction: 1.1, durationSeconds: 1.5)
    }
    .padding()
}
