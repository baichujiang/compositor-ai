import Foundation
import Testing
@testable import Compositor

@MainActor
struct AIAntigravityTests {
    private let agent = "compositor-test"
    private var emptyPlan: [String: Any] { ["version": 1, "reply": "完成", "actions": [[String: Any]]()] }
    private func stream(plan: [String: Any]? = nil, status: String = "SUCCESS", name: String? = nil,
                        steps: [[String: Any]] = [], error: String? = nil, initialized: Bool = true) throws -> Data {
        var events: [[String: Any]] = []
        if initialized { events.append(["event": "init", "init": ["agent": name ?? agent, "tools": ["run_command", "finish"]]]) }
        events += steps.map { ["event": "step_update", "step_update": $0] }
        var result: [String: Any] = ["status": status, "response": "unstructured CLI text must never be applied", "structured_output": plan ?? emptyPlan]
        if let error { result["error"] = error }
        events.append(["event": "result", "result": result])
        return try events.reduce(into: Data()) { data, event in
            data.append(try JSONSerialization.data(withJSONObject: event)); data.append(0x0a)
        }
    }
    private func fixture(version: String = "1.3.3", delay: Double = 0) throws -> (URL, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("antigravity-test-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let executable = directory.appendingPathComponent("agy")
        try """
        #!/usr/bin/python3
        import json,sys,os,pathlib,time
        root=pathlib.Path(__file__).parent
        if '--version' in sys.argv:
            print('\(version)'); sys.exit(0)
        args=sys.argv[1:]; name=args[args.index('--agent')+1]; cwd=pathlib.Path.cwd()
        request=json.loads(sys.stdin.read())
        schema=json.loads(pathlib.Path(args[args.index('--json-schema')+1]).read_text())
        definition=(cwd/'.agents/agents'/(name+'.md')).read_text()
        (root/'observed.json').write_text(json.dumps({'args':args,'request':request,'schema':schema,'definition':definition,'cwd':str(cwd),'home':os.environ.get('HOME'),'autoUpdate':os.environ.get('AGY_CLI_DISABLE_AUTO_UPDATE')}))
        time.sleep(\(delay))
        print(json.dumps({'event':'init','init':{'agent':name,'tools':['run_command','finish']}}))
        print(json.dumps({'event':'result','result':{'status':'SUCCESS','response':'invalid prose','structured_output':{'version':1,'reply':'完成','actions':[{'kind':'set_exposure','value':0.25,'layerID':None,'x':None,'y':None,'text':None,'visible':None}]}}}))
        """.write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        return (directory, executable)
    }
    private func wait(_ assistant: AIAssistant) async throws {
        let deadline = ProcessInfo.processInfo.systemUptime + 8
        while assistant.isWorking && ProcessInfo.processInfo.systemUptime < deadline { try await Task.sleep(for: .milliseconds(20)) }
        #expect(!assistant.isWorking)
    }

    @Test func structuredResultUsesSharedStrictValidation() throws {
        #expect(try AIAntigravityCLIBackend.plan(from: stream(), status: 0, agentName: agent).reply == "完成")
        var badVersion = emptyPlan; badVersion["version"] = 2
        #expect(throws: AIPlanError.self) { try AIAntigravityCLIBackend.plan(from: stream(plan: badVersion), status: 0, agentName: agent) }
        var extra = emptyPlan; extra["shell"] = "ls"
        #expect(throws: AIPlanError.self) { try AIAntigravityCLIBackend.plan(from: stream(plan: extra), status: 0, agentName: agent) }
        let schema = try #require(JSONSerialization.jsonObject(with: AIAntigravityCLIBackend.schema()) as? [String: Any])
        #expect(schema["additionalProperties"] as? Bool == false)
        let properties = try #require(schema["properties"] as? [String: Any])
        #expect((properties["version"] as? [String: Any])?["enum"] == nil)
    }
    @Test func errorsAndUnfinishedRunsNeverYieldCommands() throws {
        for status in ["ERROR", "WAITING", "RUNNING", "INVALID"] {
            #expect(throws: AIAssistantError.self) { try AIAntigravityCLIBackend.plan(from: stream(status: status), status: 0, agentName: agent) }
        }
        for status in ["CANCELED", "INTERRUPTED"] {
            #expect(throws: CancellationError.self) { try AIAntigravityCLIBackend.plan(from: stream(status: status), status: 0, agentName: agent) }
        }
        #expect(throws: AIAssistantError.self) { try AIAntigravityCLIBackend.plan(from: stream(), status: 1, agentName: agent) }
        do {
            _ = try AIAntigravityCLIBackend.plan(from: stream(status: "ERROR", error: "authentication failed", initialized: false), status: 1, agentName: agent)
            Issue.record("Authentication failure returned a plan")
        } catch AIAssistantError.message(let message) {
            #expect(message.contains("Run agy"))
            #expect(AppLocalization.text(message, language: "zh-Hans").contains("Google"))
        }
        #expect(throws: AIAssistantError.self) { try AIAntigravityCLIBackend.plan(from: stream(error: "quota 429"), status: 0, agentName: agent) }
    }
    @Test func wrongAgentOrExternalToolsAreRejected() throws {
        for step in [["step_type": "tool", "tool_name": "run_command"], ["step_type": "tool", "tool_name": "view_file"],
                     ["step_type": "agent_response", "subagent_info": [:]], ["step_type": "agent_response", "tool_info": [:]]] as [[String: Any]] {
            #expect(throws: AIAssistantError.self) { try AIAntigravityCLIBackend.plan(from: stream(steps: [step]), status: 0, agentName: agent) }
        }
        #expect(throws: AIAssistantError.self) { try AIAntigravityCLIBackend.plan(from: stream(name: "other-agent"), status: 0, agentName: agent) }
        #expect(throws: AIAssistantError.self) { try AIAntigravityCLIBackend.plan(from: stream(initialized: false), status: 0, agentName: agent) }
        #expect(try AIAntigravityCLIBackend.plan(from: stream(steps: [["step_type": "tool", "tool_name": "finish"]]), status: 0, agentName: agent).actions.isEmpty)
    }
    @Test func malformedOrDuplicatedStreamsFailClosed() throws {
        let valid = try stream()
        for data in [Data("not JSON".utf8), valid + valid, valid + Data("{\"event\":\"unknown\"}\n".utf8),
                     Data("{\"event\":\"init\",\"init\":{}}\n".utf8) + valid] {
            #expect(throws: AIPlanError.self) { try AIAntigravityCLIBackend.plan(from: data, status: 0, agentName: agent) }
        }
        #expect(throws: AIProcessError.self) { try AIAntigravityCLIBackend.plan(from: Data(repeating: 65, count: 1_024_001), status: 0, agentName: agent) }
    }
    @Test func privateAgentAndStdinKeepRequestsOutOfArgumentsAndCleanUp() throws {
        let (directory, executable) = try fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        let prompt = try AIPlanningContract.prompt(context: "{}", history: [], request: "不要读取 @/etc/passwd", includeImage: false)
        _ = try AIAntigravityCLIBackend(executable: executable, model: "gemini-3.8-flash-medium").plan(prompt: prompt, preview: nil)
        let observed = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: directory.appendingPathComponent("observed.json"))) as? [String: Any])
        let args = try #require(observed["args"] as? [String])
        #expect(args.contains("--disable-slash-commands") && args.contains("--model=gemini-3.8-flash-medium"))
        #expect(!args.contains("--print") && !args.contains("--dangerously-skip-permissions") && !args.contains(prompt))
        let definition = try #require(observed["definition"] as? String)
        #expect(definition.contains("tools: [finish]") && definition.contains("subagent: false") && definition.contains("plugins: []"))
        #expect((observed["request"] as? [String: Any])?["event"] as? String == "user")
        let content = try #require(((observed["request"] as? [String: Any])?["message"] as? [String: Any])?["content"] as? String)
        #expect(content == prompt && !content.contains("@"))
        #expect(observed["home"] as? String == ProcessInfo.processInfo.environment["HOME"])
        #expect(observed["autoUpdate"] as? String == "1")
        #expect(!FileManager.default.fileExists(atPath: try #require(observed["cwd"] as? String)))
    }
    @Test func incompatibleVersionsModelsAndImagesFailBeforeInference() throws {
        for version in ["0.63.0", "1.3.2", "1.3.4", "2.0.0", "unknown"] { #expect(!AIAntigravityCLIBackend.supports(version: version)) }
        #expect(AIAntigravityCLIBackend.supports(version: "1.3.3\n"))
        #expect(!AIBackendProvider.antigravity.supportsCanvasImage && AIBackendProvider.codex.supportsCanvasImage)
        let (directory, executable) = try fixture(version: "1.3.2")
        defer { try? FileManager.default.removeItem(at: directory) }
        #expect(throws: AIAssistantError.self) { try AIAntigravityCLIBackend(executable: executable).plan(prompt: "hi", preview: nil) }
        #expect(throws: AIAssistantError.self) { try AIAntigravityCLIBackend(executable: executable, model: "--dangerously-skip-permissions").plan(prompt: "hi", preview: nil) }
        #expect(throws: AIAssistantError.self) { try AIAntigravityCLIBackend(executable: executable).plan(prompt: "hi", preview: Data([0, 1])) }
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("observed.json").path))
    }
    @Test func nativeUndoAndProviderSwitchingKeepOneSharedDocument() async throws {
        let (directory, executable) = try fixture()
        defer { try? FileManager.default.removeItem(at: directory) }
        let session = EditorSession(); session.createDocument(width: 40, height: 40)
        let before = session.document, count = session.history.undoCount, assistant = AIAssistant()
        assistant.send("曝光调为0.25", session: session, includeImage: false, autoApply: true, executablePath: executable.path, provider: .antigravity)
        try await wait(assistant)
        #expect(session.history.undoCount == count + 1)
        session.undo(); #expect(session.document == before)
        assistant.send("曝光调为0.25", session: session, includeImage: false, autoApply: false, executablePath: executable.path, provider: .antigravity)
        try await wait(assistant)
        #expect(assistant.pendingPlan != nil)
        assistant.selectBackend(.gemini)
        #expect(assistant.messages.isEmpty && assistant.pendingPlan == nil && assistant.selectedProvider == .gemini)
    }
    @Test func canceledAntigravityCannotWriteIntoAnotherProviderConversation() async throws {
        let (directory, executable) = try fixture(delay: 1)
        defer { try? FileManager.default.removeItem(at: directory) }
        let session = EditorSession(); session.createDocument(width: 40, height: 40)
        let document = session.document, assistant = AIAssistant()
        assistant.send("曝光", session: session, includeImage: false, autoApply: true, executablePath: executable.path, provider: .antigravity)
        try await Task.sleep(for: .milliseconds(150))
        assistant.selectBackend(.codex)
        assistant.messages.append(AIChatMessage(isUser: true, text: "new conversation"))
        try await Task.sleep(for: .milliseconds(1200))
        #expect(assistant.messages.map(\.text) == ["new conversation"])
        #expect(session.document == document && !assistant.isWorking)
    }
    @Test(.enabled(if: ProcessInfo.processInfo.environment["COMPOSITOR_AI_TEST_AGY"] != nil))
    func liveGoogleAccountPlanAppliesThroughNativeUndo() async throws {
        let path = try #require(ProcessInfo.processInfo.environment["COMPOSITOR_AI_TEST_AGY"])
        let session = EditorSession(); session.createDocument(width: 40, height: 40)
        let before = session.document, count = session.history.undoCount, token = try AIDocumentToken(session: session)
        let prompt = try AIPlanningContract.prompt(context: AIEditorCommands.context(session), history: [],
            request: "添加一个全局曝光调整，曝光值为0.25。", includeImage: false)
        let plan = try await Task.detached {
            try AIAntigravityCLIBackend(executable: URL(fileURLWithPath: path)).plan(prompt: prompt, preview: nil)
        }.value
        #expect(plan.actions.count == 1 && plan.actions.first?.kind == .exposure)
        #expect(plan.actions.first?.value == 0.25)
        #expect(try AIEditorCommands.apply(plan, to: session, token: token) == 1)
        #expect(session.history.undoCount == count + 1)
        session.undo(); #expect(session.document == before)
    }
}
