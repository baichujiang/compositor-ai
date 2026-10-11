import Foundation
import ImageIO
import Testing
@testable import Compositor

private nonisolated final class GatewayTestBackend: AIBackend, @unchecked Sendable {
    let result: AIEditPlan
    private let lock = NSLock()
    private var inputs: [(String, Data?)] = []
    init(actions: [AIEditorCommand] = [AIEditorCommand(kind: .zoom, value: 125)]) {
        result = AIEditPlan(reply: "完成", actions: actions)
    }
    var received: [(String, Data?)] { lock.lock(); defer { lock.unlock() }; return inputs }
    func plan(prompt: String, preview: Data?) throws -> AIEditPlan {
        lock.lock(); inputs.append((prompt, preview)); lock.unlock()
        return result
    }
    func cancel() {}
}

/// Deliberately contains no EditorSession, document, renderer, or native history.
@MainActor private final class GatewayTestEditor: AIEditorGateway {
    var canSendRequest = true
    var context = "{\"apiVersion\":1,\"host\":\"independent editor\"}"
    var valid = true
    var previewDelay: Duration = .zero
    var captured: Set<AIRequestToken> = []
    var released: [AIRequestToken] = []
    var previewCount = 0
    var applied: [AIEditPlan] = []
    let image = Data([1, 2, 3])
    func layerName(for id: UUID?) -> String? { "Independent layer" }
    func capture(includeImage: Bool) throws -> AIEditorRequest {
        let token = AIRequestToken()
        captured.insert(token)
        return AIEditorRequest(token: token, context: context, preview: {
            self.previewCount += 1
            try await Task.sleep(for: self.previewDelay)
            return self.image
        })
    }
    func validate(_ token: AIRequestToken) throws {
        guard valid, captured.contains(token) else { throw AIAssistantError.message("stale") }
    }
    func apply(_ plan: AIEditPlan, token: AIRequestToken) throws -> Int {
        try validate(token)
        applied.append(plan)
        return plan.actions.count
    }
    func release(_ token: AIRequestToken) { captured.remove(token); released.append(token) }
}

@MainActor struct AIEditorGatewayTests {
    private func wait(until condition: () -> Bool) async throws {
        let deadline = ProcessInfo.processInfo.systemUptime + 3
        while !condition() && ProcessInfo.processInfo.systemUptime < deadline { try await Task.sleep(for: .milliseconds(10)) }
        #expect(condition())
    }
    private func send(_ assistant: AIAssistant, editor: any AIEditorGateway, image: Bool = false, autoApply: Bool = true) {
        assistant.send("缩放画布", editor: editor, includeImage: image, autoApply: autoApply, executablePath: "/usr/bin/true")
    }

    @Test func assistantRunsThroughAnIndependentEditorGateway() async throws {
        let editor = GatewayTestEditor(), backend = GatewayTestBackend()
        let assistant = AIAssistant(makeBackend: { _ in backend })
        send(assistant, editor: editor, image: true)
        try await wait { !assistant.isWorking }
        #expect(backend.received.count == 1 && backend.received.first?.1 == editor.image)
        #expect(backend.received.first?.0.contains("independent editor") == true)
        #expect(editor.previewCount == 1 && editor.applied.count == 1)
        #expect(editor.captured.isEmpty && editor.released.count == 1)
    }

    @Test func textOnlyRequestNeverInvokesTheHostsPreviewClosure() async throws {
        let editor = GatewayTestEditor(), backend = GatewayTestBackend()
        let assistant = AIAssistant(makeBackend: { _ in backend })
        send(assistant, editor: editor)
        try await wait { !assistant.isWorking }
        #expect(editor.previewCount == 0 && backend.received.first?.1 == nil)
        #expect(editor.applied.count == 1 && editor.captured.isEmpty)
    }

    @Test func pendingPlanKeepsItsOriginalGatewayAndReleasesItAfterApply() async throws {
        let editor = GatewayTestEditor(), backend = GatewayTestBackend()
        let assistant = AIAssistant(makeBackend: { _ in backend })
        send(assistant, editor: editor, autoApply: false)
        try await wait { !assistant.isWorking }
        #expect(assistant.pendingPlan != nil && editor.captured.count == 1 && editor.applied.isEmpty)
        assistant.applyPending()
        #expect(editor.applied.count == 1 && editor.captured.isEmpty && assistant.pendingPlan == nil)
        assistant.applyPending()
        #expect(editor.applied.count == 1 && editor.released.count == 1)
    }

    @Test func stalePendingPlanCannotApplyAndReleasesItsCapture() async throws {
        let editor = GatewayTestEditor(), backend = GatewayTestBackend()
        let assistant = AIAssistant(makeBackend: { _ in backend })
        send(assistant, editor: editor, autoApply: false)
        try await wait { !assistant.isWorking }
        editor.valid = false
        assistant.applyPending()
        #expect(editor.applied.isEmpty && editor.captured.isEmpty && assistant.pendingPlan == nil)
        #expect(assistant.status == "stale")
    }

    @Test func aNewGatewayDiscardsTheOldPendingCapture() async throws {
        let first = GatewayTestEditor(), second = GatewayTestEditor(), backend = GatewayTestBackend()
        let assistant = AIAssistant(makeBackend: { _ in backend })
        send(assistant, editor: first, autoApply: false)
        try await wait { !assistant.isWorking }
        send(assistant, editor: second, autoApply: false)
        try await wait { !assistant.isWorking }
        #expect(first.captured.isEmpty && first.applied.isEmpty && second.captured.count == 1)
        assistant.discardPending()
        #expect(second.captured.isEmpty && second.applied.isEmpty)
    }

    @Test func clearingDuringPreviewCancelsAndReleasesWithoutCallingThePlanner() async throws {
        let editor = GatewayTestEditor(), backend = GatewayTestBackend()
        editor.previewDelay = .seconds(5)
        let assistant = AIAssistant(makeBackend: { _ in backend })
        send(assistant, editor: editor, image: true)
        try await wait { editor.previewCount == 1 }
        assistant.clear()
        try await wait { editor.captured.isEmpty }
        #expect(backend.received.isEmpty && editor.applied.isEmpty && assistant.messages.isEmpty)
    }

    @Test func malformedHostContextReleasesBeforeStartingThePlanner() {
        let editor = GatewayTestEditor(), backend = GatewayTestBackend()
        editor.context = "invalid JSON"
        let assistant = AIAssistant(makeBackend: { _ in backend })
        send(assistant, editor: editor)
        #expect(!assistant.isWorking && backend.received.isEmpty && editor.captured.isEmpty)
        #expect(editor.released.count == 1)
    }

    @Test func replyOnlyPlansReleaseTheirCaptureWithoutAnEdit() async throws {
        let editor = GatewayTestEditor(), backend = GatewayTestBackend(actions: [])
        let assistant = AIAssistant(makeBackend: { _ in backend })
        send(assistant, editor: editor, autoApply: false)
        try await wait { !assistant.isWorking }
        #expect(editor.applied.isEmpty && editor.captured.isEmpty && assistant.pendingPlan == nil)
        #expect(assistant.messages.last?.text == "完成")
    }

    @Test func nativeAdapterRejectsForeignReleasedAndDetachedHandles() throws {
        let session = EditorSession(); session.createDocument(width: 40, height: 40)
        let first = AINativeEditorAdapter(session: session), second = AINativeEditorAdapter(session: session)
        let capture = try first.capture(includeImage: false)
        #expect(throws: AIAssistantError.self) { try second.validate(capture.token) }
        first.release(capture.token)
        #expect(throws: AIAssistantError.self) { try first.validate(capture.token) }
        let next = try first.capture(includeImage: false)
        first.detach()
        #expect(!first.canSendRequest)
        #expect(throws: AIAssistantError.self) { try first.apply(AIEditPlan(reply: "", actions: [AIEditorCommand(kind: .zoom, value: 125)]), token: next.token) }
    }

    @Test func nativeAdapterDoesNotRetainClosedEditorSessions() throws {
        var session: EditorSession? = EditorSession()
        if let session { session.createDocument(width: 40, height: 40) }
        weak var observed = session
        let adapter = AINativeEditorAdapter(session: try #require(session))
        let capture = try adapter.capture(includeImage: false)
        session = nil
        #expect(observed == nil && !adapter.canSendRequest)
        #expect(throws: AIAssistantError.self) { try adapter.validate(capture.token) }
        adapter.release(capture.token)
    }

    @Test func nativePreviewIsOptInAndKeepsDocumentCoordinates() async throws {
        let session = EditorSession(); session.createDocument(width: 1600, height: 100)
        let adapter = AINativeEditorAdapter(session: session)
        let text = try adapter.capture(includeImage: false)
        #expect(text.preview == nil)
        adapter.release(text.token)
        let image = try adapter.capture(includeImage: true)
        defer { adapter.release(image.token) }
        let render = try #require(image.preview)
        let data = try await render()
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        let dimensions = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any])
        #expect(dimensions[kCGImagePropertyPixelWidth as String] as? Int == 1400)
        let context = try #require(JSONSerialization.jsonObject(with: Data(image.context.utf8)) as? [String: Any])
        #expect((context["canvas"] as? [String: Int])?["width"] == 1600)
    }

    @Test func integrationKeepsPerTabStateAndDetachesClosedTabs() throws {
        let first = EditorSession(), second = EditorSession()
        first.createDocument(width: 40, height: 40); second.createDocument(width: 40, height: 40)
        let integration = AIApplicationIntegration()
        let state = integration.state(for: first), other = integration.state(for: second)
        #expect(state === integration.state(for: first) && state !== other)
        #expect(!state.showsAssistant && !other.showsAssistant)
        state.showsAssistant = true
        state.assistant.messages.append(AIChatMessage(isUser: true, text: "first tab"))
        #expect(other.assistant.messages.isEmpty && !other.showsAssistant)
        integration.retainSessions([second])
        #expect(state.assistant.messages.isEmpty && !state.showsAssistant && !state.editor.canSendRequest)
        #expect(other === integration.state(for: second))
    }

    @Test func documentChangeHookClearsOnlyTheAffectedAssistant() {
        let first = EditorSession(), second = EditorSession(), integration = AIApplicationIntegration()
        let state = integration.state(for: first), other = integration.state(for: second)
        state.assistant.messages.append(AIChatMessage(isUser: true, text: "first"))
        other.assistant.messages.append(AIChatMessage(isUser: true, text: "second"))
        integration.hooks.documentChanged(first)
        #expect(state.assistant.messages.isEmpty && other.assistant.messages.map(\.text) == ["second"])
    }
}
