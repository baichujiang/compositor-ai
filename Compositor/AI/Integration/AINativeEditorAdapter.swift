import Foundation
import CoreGraphics

/// The host owns native snapshots, preview rendering, and execution. AI receives only data and handles.
final class AINativeEditorAdapter: AIEditorGateway {
    private(set) weak var session: EditorSession?
    private var captures: [AIRequestToken: AIDocumentToken] = [:]

    init(session: EditorSession) { self.session = session }

    var canSendRequest: Bool {
        guard let session else { return false }
        return session.canEditLayers && session.effectsEditing == nil && session.colorPicker == nil && session.opacityEditLayerID == nil
    }

    func layerName(for id: UUID?) -> String? {
        session?.document?.layers.first(where: { $0.id == id })?.name
    }

    func capture(includeImage: Bool) throws -> AIEditorRequest {
        guard let session, canSendRequest else {
            throw AIAssistantError.message("Open a canvas and finish the current edit before sending a request.")
        }
        let document = try AIDocumentToken(session: session)
        if includeImage, document.document.width * document.document.height > 25_000_000 {
            throw AIAssistantError.message("Canvas images are limited to 25 megapixels for AI previews. Disable Include canvas image for this document.")
        }
        let context = try AIEditorCommands.context(session)
        let snapshot = includeImage ? session.projectSnapshot() : nil
        let token = AIRequestToken()
        captures[token] = document
        let preview: (@MainActor () async throws -> Data)?
        if let snapshot {
            preview = { @MainActor in
                let raster = try await ImageExporter.shared.render(snapshot)
                try Task.checkCancellation()
                let ratio = min(1, 1400 / Double(max(raster.image.width, raster.image.height)))
                let resized = try await ImageExporter.shared.resized(raster,
                    width: max(1, Int(Double(raster.image.width) * ratio)),
                    height: max(1, Int(Double(raster.image.height) * ratio)))
                return try await ImageExporter.shared.pngData(resized)
            }
        } else { preview = nil }
        return AIEditorRequest(token: token, context: context, preview: preview)
    }

    func validate(_ token: AIRequestToken) throws {
        let (session, capture) = try captured(token)
        try capture.check(session)
    }

    @discardableResult func apply(_ plan: AIEditPlan, token: AIRequestToken) throws -> Int {
        let (session, capture) = try captured(token)
        return try AIEditorCommands.apply(plan, to: session, token: capture)
    }

    func release(_ token: AIRequestToken) { captures[token] = nil }

    func detach() {
        captures.removeAll()
        session = nil
    }

    private func captured(_ token: AIRequestToken) throws -> (EditorSession, AIDocumentToken) {
        guard let session, let capture = captures[token] else {
            throw AIAssistantError.message("The document changed while AI was working. Send the request again using the current canvas.")
        }
        return (session, capture)
    }
}
