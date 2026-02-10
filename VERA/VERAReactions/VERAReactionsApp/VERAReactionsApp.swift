//
//  Created by Vonage on 02/09/2026.
//

import SwiftUI
import VERAReactions

@main
struct VERAReactionsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedEmoji: EmojiItem?
    
    var body: some View {
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
    ContentView()
}
