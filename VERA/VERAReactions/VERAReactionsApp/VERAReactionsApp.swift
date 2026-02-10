//
//  Created by Vonage on 02/09/2026.
//

import SwiftUI
import VERAReactions

@main
struct VERAReactionsApp: App {
    var body: some Scene {
        WindowGroup {
            DemoEmojiPickerView()
        }
    }
}

struct DemoEmojiPickerView: View {
    @State private var selectedEmoji: EmojiItem?
    
    var body: some View {
        ZStack {
            // Simulated video background
            LinearGradient(
                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // EmojiPickerView overlay
            emjoyPickerContainerView

            // Demo controls
            VStack {
                Text("EmojiPickerView Demo")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding()

                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var emjoyPickerContainerView : some View  {
        VStack(spacing: 32) {
            Text(selectedEmoji?.emoji ?? "👆")
                .font(.system(size: 64))
            
            Text(selectedEmoji?.name ?? "Tap an emoji")
                .font(.headline)
            
            EmojiPickerViewFactory.make(configuration: .default) { emoji in
                selectedEmoji = emoji
            }
        }
        .padding()
    }
}

#Preview {
    DemoEmojiPickerView()
}
