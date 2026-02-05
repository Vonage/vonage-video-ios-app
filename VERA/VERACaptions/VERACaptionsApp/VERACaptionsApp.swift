//
//  Created by Vonage on 10/10/25.
//

import SwiftUI
import VERACaptions

@main
struct VERACaptionsApp: App {

    var body: some Scene {
        WindowGroup {
            CaptionsDemoView()
        }
    }
}

struct CaptionsDemoView: View {
    @State private var captions: [CaptionItem] = []
    @State private var currentIndex = 0

    private let demoMessages: [(speaker: String, text: String)] = [
        ("Alice", "Hello everyone, welcome to today's meeting!"),
        ("Bob", "Thanks for joining, let's get started."),
        ("Charlie", "I have a few updates to share."),
        ("Alice", "Great! Let's hear them."),
        ("Bob", "First, the project is progressing well."),
        ("Charlie", "We've completed the initial phase ahead of schedule."),
        ("Alice", "That's excellent news!"),
        ("Bob", "The team has done an amazing job."),
        ("Charlie", "Next, we need to discuss the upcoming milestones."),
        ("Alice", "I agree, let's review the timeline."),
    ]

    var body: some View {
        ZStack {
            // Simulated video background
            LinearGradient(
                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Captions overlay
            CaptionsView(captions: captions)

            // Demo controls
            VStack {
                Text("Captions Demo")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding()

                Spacer()
            }
        }
        .onAppear {
            startCaptionsDemo()
        }
    }

    private func startCaptionsDemo() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
            guard currentIndex < demoMessages.count else {
                timer.invalidate()
                return
            }

            let message = demoMessages[currentIndex]
            let newCaption = CaptionItem(
                speakerName: message.speaker,
                text: message.text
            )

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                captions.append(newCaption)
            }

            // Remove old captions after 8 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    captions.removeAll { $0.id == newCaption.id }
                }
            }

            currentIndex += 1
        }
    }
}
