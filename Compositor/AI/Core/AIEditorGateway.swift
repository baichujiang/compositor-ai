import Foundation

/// An opaque handle owned by the host. No native document or history types cross this boundary.
nonisolated struct AIRequestToken: Hashable, Sendable {
    let id = UUID()
}

struct AIEditorRequest {
    let token: AIRequestToken
    let context: String
    let preview: (@MainActor () async throws -> Data)?
}

/// Planning depends on this interface; only the integration layer knows the native editor.
@MainActor protocol AIEditorGateway: AnyObject {
    var canSendRequest: Bool { get }
    func layerName(for id: UUID?) -> String?
    func capture(includeImage: Bool) throws -> AIEditorRequest
    func validate(_ token: AIRequestToken) throws
    @discardableResult func apply(_ plan: AIEditPlan, token: AIRequestToken) throws -> Int
    func release(_ token: AIRequestToken)
}
