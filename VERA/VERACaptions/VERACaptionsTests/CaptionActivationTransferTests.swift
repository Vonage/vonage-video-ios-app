//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERACaptions

@Suite("Caption activation request transfer")
struct CaptionActivationTransferTests {
    @Test(arguments: ["", "room/東京?user=Zoë", "room/with spaces"])
    func requestsCrossTasksAndCustomerUseCaseActor(sessionKey: String) async throws {
        let activation = CaptionActivation()
        let useCase: any EnableCaptionsUseCase = activation
        let request = await transfer(EnableCaptionsRequest(sessionKey: sessionKey))
        try await useCase(request)
        #expect(await activation.sessionKeys == [sessionKey])
    }

    private func transfer<Value: Sendable>(_ value: Value) async -> Value {
        await Task.detached { value }.value
    }
}

private actor CaptionActivation: EnableCaptionsUseCase {
    private(set) var sessionKeys: [String] = []

    func callAsFunction(_ request: EnableCaptionsRequest) async throws {
        sessionKeys.append(request.sessionKey)
    }
}
