import Foundation
import Observation

struct AIChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
}

@Observable
final class AIAssistant {
    private(set) var selectedProvider: AIBackendProvider = .codex
    var messages: [AIChatMessage] = []
    var isWorking = false
    var status = ""
    var pendingPlan: AIEditPlan?
    @ObservationIgnored private var pendingToken: AIRequestToken?
    @ObservationIgnored private var pendingEditor: (any AIEditorGateway)?
    @ObservationIgnored private var request: Task<Void, Never>?
    @ObservationIgnored private var backend: (any AIBackend)?
    @ObservationIgnored private var requestID: UUID?
    @ObservationIgnored private let makeBackend: (AIBackendRequest) -> any AIBackend

    init(makeBackend: @escaping (AIBackendRequest) -> any AIBackend = {
        $0.provider.backend(executable: $0.executable, model: $0.model, onStatus: $0.onStatus)
    }) {
        self.makeBackend = makeBackend
    }

    private func releasePending() {
        if let token = pendingToken { pendingEditor?.release(token) }
        pendingPlan = nil
        pendingToken = nil
        pendingEditor = nil
    }

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
        releasePending()
        status = ""
    }

    func discardPending() {
        releasePending()
        messages.append(AIChatMessage(isUser: false, text: L("Proposed changes discarded. The document was not changed.")))
        status = "Ready"
    }

    func selectBackend(_ provider: AIBackendProvider) {
        guard selectedProvider != provider else { return }
        clear()
        selectedProvider = provider
    }

    func send(_ text: String, editor: any AIEditorGateway, includeImage: Bool, autoApply: Bool, executablePath: String, provider: AIBackendProvider = .codex, model: String = "") {
        guard !isWorking else { return }
        selectBackend(provider)
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        var captured: AIEditorRequest?
        do {
            guard text.count <= 8_000 else { throw AIAssistantError.message("Keep requests under 8,000 characters.") }
            guard editor.canSendRequest else {
                throw AIAssistantError.message("Open a canvas and finish the current edit before sending a request.")
            }
            guard let executable = provider.findExecutable(customPath: executablePath) else {
                throw AIAssistantError.message(LF("%@ was not found. Install it, sign in, or choose its executable in Settings.", provider.title))
            }
            let capture = try editor.capture(includeImage: includeImage)
            captured = capture
            let recent = messages.suffix(12).map { ["role": $0.isUser ? "user" : "assistant", "text": $0.text] }
            let prompt = try AIPlanningContract.prompt(context: capture.context, history: recent, request: text, includeImage: includeImage)
            releasePending()
            messages.append(AIChatMessage(isUser: true, text: text))
            if messages.count > 80 { messages.removeFirst(messages.count - 80) }
            let id = UUID()
            let backend = makeBackend(AIBackendRequest(provider: provider, executable: executable, model: model) { [weak self] status in
                Task { @MainActor [weak self] in
                    if self?.requestID == id { self?.status = status }
                }
            })
            self.backend = backend
            requestID = id
            isWorking = true
            status = includeImage ? "Rendering canvas…" : "Thinking…"
            request = Task { [weak self] in
                guard let self else { editor.release(capture.token); return }
                defer {
                    if self.pendingToken != capture.token { editor.release(capture.token) }
                    if self.requestID == id {
                        self.isWorking = false
                        self.request = nil
                        self.backend = nil
                        self.requestID = nil
                    }
                }
                do {
                    let image = includeImage ? try await capture.preview?() : nil
                    try Task.checkCancellation()
                    guard self.requestID == id else { return }
                    self.status = "Thinking…"
                    let plan = try await withTaskCancellationHandler {
                        try await Task.detached(priority: .userInitiated) { try backend.plan(prompt: prompt, preview: image) }.value
                    } onCancel: { backend.cancel() }
                    try Task.checkCancellation()
                    guard self.requestID == id else { return }
                    try editor.validate(capture.token)
                    if plan.actions.isEmpty { self.status = "Ready" }
                    else if autoApply {
                        let count = try editor.apply(plan, token: capture.token)
                        self.status = LF("Applied %lld commands. Undo with ⌘Z.", count)
                    } else {
                        self.pendingPlan = plan
                        self.pendingToken = capture.token
                        self.pendingEditor = editor
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
        } catch {
            if let captured { editor.release(captured.token) }
            status = error.localizedDescription
        }
    }

    func applyPending() {
        guard let plan = pendingPlan, let token = pendingToken, let editor = pendingEditor else { return }
        do {
            let count = try editor.apply(plan, token: token)
            status = LF("Applied %lld commands. Undo with ⌘Z.", count)
            messages.append(AIChatMessage(isUser: false, text: status))
        } catch {
            status = error.localizedDescription
            messages.append(AIChatMessage(isUser: false, text: LF("No changes applied. %@", error.localizedDescription)))
        }
        releasePending()
    }
}
