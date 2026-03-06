//
//  Created by Vonage on 05/03/2026.
//

func delay() async {
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
}
