//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERADomain

@Suite("Background image descriptor value transfer")
struct VideoBackgroundTransferTests {

    @Test("Stock and uploaded descriptor arrays preserve metadata across tasks")
    func descriptorsAcrossTasks() async {
        let stock = VideoBackgroundItem(
            id: "stock-forest", thumbnailResource: "ForestThumbnail",
            imagePath: "/fixtures/stock/forest.jpg", isUserUploaded: false)
        let uploaded = VideoBackgroundItem(
            id: "user-photo", imagePath: "/fixtures/user/会議室 🚀.jpg", isUserUploaded: true)

        for snapshot in [[], [stock], [stock, uploaded]] {
            let received = await Task.detached { snapshot }.value
            #expect(received == snapshot)
            #expect(received.map(\.id) == snapshot.map(\.id))
            #expect(received.map(\.thumbnailResource) == snapshot.map(\.thumbnailResource))
            #expect(received.map(\.imagePath) == snapshot.map(\.imagePath))
            #expect(received.map(\.isUserUploaded) == snapshot.map(\.isUserUploaded))
        }
    }

    @Test("A selected descriptor and clearing selection survive an actor round trip")
    func selectionAcrossActor() async {
        let descriptor = VideoBackgroundItem(
            id: "user-photo", imagePath: "/fixtures/user/photo.jpg", isUserUploaded: true)
        let selection = BackgroundSelection()
        for snapshot: VideoBackgroundItem? in [descriptor, nil] {
            await selection.update(snapshot)
            let received = await selection.selected
            #expect(received == snapshot)
        }
    }
}

private actor BackgroundSelection {
    private(set) var selected: VideoBackgroundItem?

    func update(_ descriptor: VideoBackgroundItem?) {
        selected = descriptor
    }
}
