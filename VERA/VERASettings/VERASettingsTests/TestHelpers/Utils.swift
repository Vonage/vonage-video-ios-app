//
//  Created by Vonage on 4/3/26.
//

func delay() async {
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
}
