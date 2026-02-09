//
//  Created by Vonage on 2/9/26.
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
