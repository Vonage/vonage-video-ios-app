import Foundation
import Testing
import VERADomain

@Suite("API response transfer")
struct APIResponseTransferTests {
    @Test("Decoded Sendable payload and both response envelopes transfer intact")
    func transfer() async throws {
        let data = Data(#"{"result":{"data":{"name":"会議","count":7,"optional":null}}}"#.utf8)
        let response = try JSONDecoder().decode(TRPCResponse<TransferPayload>.self, from: data)
        let transferred = await Task.detached { response }.value
        let stored = await ResponseStore().store(transferred)
        #expect(stored.result.data.name == "会議")
        #expect(stored.result.data.count == 7)
        #expect(stored.result.data.optional == nil)
        let result = await Task.detached { response.result }.value
        #expect(result.data == stored.result.data)
    }

    @Test("Nested optional and array payloads retain the existing JSON envelope")
    func nestedPayload() async throws {
        let data = Data(#"{"result":{"data":[null,{"name":"","count":0,"optional":"present"}]}}"#.utf8)
        let response = try JSONDecoder().decode(TRPCResponse<[TransferPayload?]>.self, from: data)
        let transferred = await Task.detached { response }.value
        #expect(transferred.result.data.count == 2)
        #expect(transferred.result.data[0] == nil)
        #expect(transferred.result.data[1]?.name == "")
        #expect(transferred.result.data[1]?.optional == "present")
    }

    @Test("Legacy non-Sendable reference payloads remain decodable")
    func legacyReferencePayload() throws {
        let data = Data(#"{"result":{"data":{"value":"original"}}}"#.utf8)
        let response = try JSONDecoder().decode(TRPCResponse<LegacyReferencePayload>.self, from: data)
        let result = try JSONDecoder().decode(
            TRPCResult<LegacyReferencePayload>.self,
            from: Data(#"{"data":{"value":"direct"}}"#.utf8))
        response.result.data.value = "changed"
        #expect(response.result.data.value == "changed")
        #expect(result.data.value == "direct")
    }
}

private struct TransferPayload: Decodable, Equatable, Sendable {
    let name: String
    let count: Int
    let optional: String?
}

private final class LegacyReferencePayload: Decodable {
    var value: String
}

private actor ResponseStore {
    private var response: TRPCResponse<TransferPayload>?

    func store(_ value: TRPCResponse<TransferPayload>) -> TRPCResponse<TransferPayload> {
        response = value
        return value
    }
}
