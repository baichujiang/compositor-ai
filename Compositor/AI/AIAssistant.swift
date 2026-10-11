import Foundation
import CoreGraphics
import Observation

struct AIChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
}

@Observable
final class AIAssistant {
    var messages: [AIChatMessage] = []
    var isWorking = false
    var status = ""
    var pendingPlan: AIEditPlan?
    @ObservationIgnored private var pendingToken: AIDocumentToken?
    @ObservationIgnored private var request: Task<Void, Never>?
    @ObservationIgnored private var backend: AICodexBackend?
    @ObservationIgnored private var requestID: UUID?

    func cancel() {
        requestID = nil
        request?.cancel()
        backend?.cancel()
        request = nil
        backend = nil
        isWorking = false
        status = "Canceled. The document was not changed."
    }

    func clear() {
        cancel()
        messages = []
        pendingPlan = nil
        pendingToken = nil
        status = ""
    }

    func discardPending() {
        pendingPlan = nil
        pendingToken = nil
        messages.append(AIChatMessage(isUser: false, text: L("Proposed changes discarded. The document was not changed.")))
        status = "Ready"
    }

    func send(_ text: String, session: EditorSession, includeImage: Bool, autoApply: Bool, executablePath: String) {
        guard !isWorking else { return }
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        do {
            guard text.count <= 8_000 else { throw AIAssistantError.message("Keep requests under 8,000 characters.") }
            guard session.canEditLayers, session.effectsEditing == nil, session.colorPicker == nil, session.opacityEditLayerID == nil else {
                throw AIAssistantError.message("Open a canvas and finish the current edit before sending a request.")
            }
            guard let executable = AICodexBackend.findExecutable(customPath: executablePath) else {
                throw AIAssistantError.message("Codex CLI was not found. Install Codex, sign in, or choose its executable in Settings below.")
            }
            let token = try AIDocumentToken(session: session)
            let context = try AIEditorCommands.context(session)
            let recent = messages.suffix(12).map { ($0.isUser ? "User: " : "Assistant: ") + $0.text }.joined(separator: "\n")
            let prompt = AICodexBackend.instructions + "\n\nConversation (previous requests only):\n" + recent
                + "\n\n<document_data>\n" + context + "\n</document_data>\n"
                + "\nCanvas image attached: \(includeImage)\nLatest user request:\n" + text
            let snapshot = includeImage ? session.projectSnapshot() : nil
            if includeImage, token.document.width * token.document.height > 25_000_000 {
                throw AIAssistantError.message("Canvas images are limited to 25 megapixels for AI previews. Disable Include canvas image for this document.")
            }
            pendingPlan = nil
            pendingToken = nil
            messages.append(AIChatMessage(isUser: true, text: text))
            if messages.count > 80 { messages.removeFirst(messages.count - 80) }
            let backend = AICodexBackend(executable: executable)
            self.backend = backend
            let id = UUID()
            requestID = id
            isWorking = true
            status = includeImage ? "Rendering canvas…" : "Thinking…"
            request = Task { [weak self] in
                guard let self else { return }
                defer {
                    if self.requestID == id {
                        self.isWorking = false
                        self.request = nil
                        self.backend = nil
                        self.requestID = nil
                    }
                }
                do {
                    var image: Data?
                    if let snapshot {
                        let raster = try await ImageExporter.shared.render(snapshot)
                        try Task.checkCancellation()
                        let ratio = min(1, 1400 / Double(max(raster.image.width, raster.image.height)))
                        let resized = try await ImageExporter.shared.resized(raster,
                            width: max(1, Int(Double(raster.image.width) * ratio)),
                            height: max(1, Int(Double(raster.image.height) * ratio)))
                        image = try await ImageExporter.shared.pngData(resized)
                    }
                    try Task.checkCancellation()
                    guard self.requestID == id else { return }
                    self.status = "Thinking…"
                    let plan = try await withTaskCancellationHandler {
                        try await Task.detached(priority: .userInitiated) { try backend.plan(prompt: prompt, preview: image) }.value
                    } onCancel: { backend.cancel() }
                    try Task.checkCancellation()
                    guard self.requestID == id else { return }
                    try token.check(session)
                    if plan.actions.isEmpty { self.status = "Ready" }
                    else if autoApply {
                        let count = try AIEditorCommands.apply(plan, to: session, token: token)
                        self.status = LF("Applied %lld commands. Undo with ⌘Z.", count)
                    } else {
                        self.pendingPlan = plan
                        self.pendingToken = token
                        self.status = LF("%lld commands ready to apply.", plan.actions.count)
                    }
                    self.messages.append(AIChatMessage(isUser: false, text: self.pendingPlan == nil ? plan.reply : LF("Proposed changes:\n%@", plan.reply)))
                } catch is CancellationError {
                    if self.requestID == id { self.status = "Canceled. The document was not changed." }
                } catch {
                    if self.requestID == id {
                        self.status = error.localizedDescription
                        self.messages.append(AIChatMessage(isUser: false, text: LF("No changes applied. %@", error.localizedDescription)))
                    }
                }
            }
        } catch { status = error.localizedDescription }
    }

    func applyPending(to session: EditorSession) {
        guard let plan = pendingPlan, let token = pendingToken else { return }
        do {
            let count = try AIEditorCommands.apply(plan, to: session, token: token)
            status = LF("Applied %lld commands. Undo with ⌘Z.", count)
            messages.append(AIChatMessage(isUser: false, text: status))
        } catch {
            status = error.localizedDescription
            messages.append(AIChatMessage(isUser: false, text: LF("No changes applied. %@", error.localizedDescription)))
        }
        pendingPlan = nil
        pendingToken = nil
    }
}
