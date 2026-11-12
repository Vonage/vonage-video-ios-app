//
//  Created by Vonage on 15/10/26.
//

import Testing
import VERADomain

@Suite("Sign-in provider descriptor transfers")
struct IDProviderTransferTests {
    @Test("A provider catalog preserves identity, labels and order across an actor boundary")
    func providerCatalogPreservesDescriptors() async {
        let original = [
            IDProvider(id: "okta", displayName: "Okta"),
            IDProvider(id: "企業", displayName: "Connexion entreprise"),
            IDProvider(id: "", displayName: ""),
        ]
        let catalog = ProviderCatalog(original)

        let transferred = await Task.detached { await catalog.providers() }.value

        #expect(transferred == original)
        #expect(transferred.map(\.id) == original.map(\.id))
        #expect(transferred.map(\.displayName) == original.map(\.displayName))
    }

    @Test("Selecting a provider sends its descriptor without normalizing its fields")
    func selectionPreservesProvider() async {
        let catalog = ProviderCatalog([])
        let selected = IDProvider(id: " enterprise ", displayName: "  Équipe 李  ")

        let transferred = await Task.detached { await catalog.select(selected) }.value

        #expect(transferred == selected)
        #expect(transferred.id == " enterprise ")
        #expect(transferred.displayName == "  Équipe 李  ")
    }
}

private actor ProviderCatalog {
    private let snapshot: [IDProvider]

    init(_ snapshot: [IDProvider]) { self.snapshot = snapshot }

    func providers() -> [IDProvider] { snapshot }
    func select(_ provider: IDProvider) -> IDProvider { provider }
}
