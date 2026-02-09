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
    var body: some View {
        VStack {
            Text("VERAReactions Demo")
                .font(.title)
            Text("Version: \(VERAReactions.version)")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
