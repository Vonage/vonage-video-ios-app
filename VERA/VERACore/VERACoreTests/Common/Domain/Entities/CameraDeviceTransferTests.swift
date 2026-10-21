//
//  Created by Vonage on 15/10/26.
//

import Testing
import VERACore

@Suite("Camera descriptor transfers")
struct CameraDeviceTransferTests {
    @Test("A camera catalog preserves order, identifiers and display names across an actor boundary")
    func catalogPreservesDescriptors() async {
        let original = [
            CameraDevice(id: "front", name: "Front camera"),
            CameraDevice(id: "背面", name: "Cámara trasera"),
            CameraDevice(id: "", name: ""),
        ]
        let catalog = CameraCatalog(original)

        let transferred = await Task.detached { await catalog.devices() }.value

        #expect(transferred.count == original.count)
        for (received, expected) in zip(transferred, original) {
            #expect(received.id == expected.id)
            #expect(received.name == expected.name)
        }
    }

    @Test("An empty camera catalog remains empty after transfer")
    func emptyCatalogRemainsEmpty() async {
        let catalog = CameraCatalog([])
        let transferred = await Task.detached { await catalog.devices() }.value
        #expect(transferred.isEmpty)
    }
}

private actor CameraCatalog {
    private let snapshot: [CameraDevice]

    init(_ snapshot: [CameraDevice]) { self.snapshot = snapshot }

    func devices() -> [CameraDevice] { snapshot }
}
