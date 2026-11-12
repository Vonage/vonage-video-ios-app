//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERABackgroundEffects
import VERADomain

@Suite("Background catalog result transfer")
struct BackgroundCatalogTransferTests {
    @Test("Empty and mixed stock/user catalogs preserve all descriptors and ordering after transfer")
    func catalogsAcrossTasksAndActor() async throws {
        let stock = VideoBackgroundItem(
            id: "stock", thumbnailResource: "background-thumb", imagePath: "/stock/東京.jpg", isUserUploaded: false)
        let uploaded = VideoBackgroundItem(
            id: "user", imagePath: "/uploads/meeting photo.jpg", isUserUploaded: true)
        let storage = BackgroundCatalogStorage()

        let catalogs: [[VideoBackgroundItem]] = [[], [stock, uploaded]]
        for items in catalogs {
            let result = await transfer(GetBackgroundsUseCaseResult(backgrounds: items))
            await storage.update(result)
            let received = try #require(await storage.result)
            #expect(received.backgrounds == items)
        }
    }

    @Test("Editing a returned catalog array leaves the original and actor snapshot unchanged")
    func catalogCopiesRemainIndependent() async throws {
        let item = VideoBackgroundItem(id: "stock", imagePath: "/stock/image.jpg", isUserUploaded: false)
        let original = GetBackgroundsUseCaseResult(backgrounds: [item])
        let storage = BackgroundCatalogStorage()
        await storage.update(original)
        let transferred = await transfer(original)
        var edited = transferred.backgrounds
        edited.removeAll()
        #expect(edited.isEmpty)
        #expect(original.backgrounds == [item])
        let stored = try #require(await storage.result)
        #expect(stored.backgrounds == [item])
    }

    private func transfer<Value: Sendable>(_ value: Value) async -> Value {
        await Task.detached { value }.value
    }
}

private actor BackgroundCatalogStorage {
    private(set) var result: GetBackgroundsUseCaseResult?

    func update(_ value: GetBackgroundsUseCaseResult) {
        result = value
    }
}
