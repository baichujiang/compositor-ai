import Foundation

nonisolated final class AIAntigravityCLIBackend: AIBackend, @unchecked Sendable {
    let executable: URL
    let model: String
    private let runner = AIProcessRunner()

    init(executable: URL, model: String = "") {
        self.executable = executable
        self.model = model.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    func cancel() { runner.cancel() }

    // Pin the tested CLI: its agent allowlist and streaming protocol are part of this boundary.
    static func supports(version: String) -> Bool {
        version.trimmingCharacters(in: .whitespacesAndNewlines) == "1.3.3"
    }
    static func agentDefinition(name: String) -> String {
        """
        ---
        name: \(name)
        description: Return a typed Compositor edit plan without external tools.
        mainAgent: true
        subagent: false
        tools: [finish]
        mcpServers: []
        skills: []
        plugins: []
        commandExecutionPolicy: "off"
        ---
        \(AIPlanningContract.instructions)
        Do not manage tasks or invoke subagents. Only finish may be used if structured output requires it.
        """
    }
    static func schema() throws -> Data {
        var schema = try JSONSerialization.jsonObject(with: AIPlanningContract.schema()) as! [String: Any]
        var properties = schema["properties"] as! [String: Any]
        var version = properties["version"] as! [String: Any]
        // This CLI's Google schema conversion rejects numeric enum values. The shared decoder still requires version 1.
        version.removeValue(forKey: "enum")
        properties["version"] = version
        schema["properties"] = properties
        return try JSONSerialization.data(withJSONObject: schema, options: .sortedKeys)
    }
    func plan(prompt: String, preview: Data?) throws -> AIEditPlan {
        guard preview == nil else {
            throw AIAssistantError.message("Canvas images are not supported by Antigravity CLI in this preview. Choose Codex or Gemini CLI for canvas input.")
        }
        guard model.isEmpty || model.range(of: "^[A-Za-z0-9][A-Za-z0-9._:/-]{0,119}$", options: .regularExpression) != nil else {
            throw AIAssistantError.message("Enter a valid Antigravity model name, or leave it blank for the CLI default.")
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("compositor-antigravity-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: directory) }
        let name = "compositor-planner-" + UUID().uuidString.lowercased()
        let agents = directory.appendingPathComponent(".agents/agents")
        try FileManager.default.createDirectory(at: agents, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try Self.agentDefinition(name: name).write(to: agents.appendingPathComponent(name + ".md"), atomically: true, encoding: .utf8)
        let schema = directory.appendingPathComponent("schema.json")
        try Self.schema().write(to: schema)
        var environment = AIExecutableLocator.environment(for: executable)
        environment["AGY_CLI_DISABLE_AUTO_UPDATE"] = "1"
        let deadline = ProcessInfo.processInfo.systemUptime + 180
        let version = try runner.run(executable: executable, arguments: ["--version"], directory: directory,
                                     environment: environment, timeout: 12)
        guard version.status == 0, Self.supports(version: String(decoding: version.output, as: UTF8.self)) else {
            throw AIAssistantError.message("Antigravity CLI 1.3.3 is required for this preview. Choose its compatible executable in Settings.")
        }
        var arguments = ["--agent", name, "--input-format", "stream-json", "--output-format", "stream-json",
                         "--json-schema", schema.path, "--disable-slash-commands", "--print-timeout", "150s",
                         "--log-file", directory.appendingPathComponent("cli.log").path]
        if !model.isEmpty { arguments.append("--model=" + model) }
        var input = try JSONSerialization.data(withJSONObject: ["event": "user", "message": ["content": prompt]], options: .sortedKeys)
        input.append(0x0a)
        let result = try runner.run(executable: executable, arguments: arguments, directory: directory,
                                    environment: environment, input: input, timeout: max(0.01, deadline - ProcessInfo.processInfo.systemUptime))
        return try Self.plan(from: result.output, status: result.status, diagnostics: result.diagnostics, agentName: name)
    }
    static func plan(from data: Data, status: Int32, diagnostics: Data = Data(), agentName: String) throws -> AIEditPlan {
        guard data.count <= 1_024_000 else { throw AIProcessError.outputLimit }
        var initialization: [String: Any]?
        var initializationCount = 0
        var result: [String: Any]?
        var usedExternalTool = false
        var invalidStream = false
        for line in data.split(separator: 0x0a) where !line.allSatisfy({ $0 == 0x20 || $0 == 0x0d || $0 == 0x09 }) {
            guard let event = (try? JSONSerialization.jsonObject(with: Data(line))) as? [String: Any] else { throw AIPlanError.format }
            switch event["event"] as? String {
            case "init":
                initializationCount += 1
                if initializationCount != 1 || result != nil { invalidStream = true }
                initialization = event["init"] as? [String: Any]
                if initialization == nil { invalidStream = true }
            case "step_update":
                guard initialization != nil, result == nil, let step = event["step_update"] as? [String: Any] else { invalidStream = true; continue }
                if step["subagent_info"] != nil { usedExternalTool = true }
                if step["step_type"] as? String == "tool" {
                    if step["tool_name"] as? String != "finish" { usedExternalTool = true }
                } else if step["tool_info"] != nil || step["tool_name"] != nil { usedExternalTool = true }
            case "result":
                if result != nil { invalidStream = true }
                result = event["result"] as? [String: Any]
            default: invalidStream = true
            }
        }
        guard !invalidStream, let result else { throw AIPlanError.format }
        let terminal = result["status"] as? String
        if terminal == "CANCELED" || terminal == "INTERRUPTED" { throw CancellationError() }
        guard status == 0, terminal == "SUCCESS", result["error"] == nil else {
            let diagnostic = String(decoding: diagnostics, as: UTF8.self) + (result["error"] as? String ?? "")
            if diagnostic.localizedCaseInsensitiveContains("auth") || diagnostic.contains("401") || diagnostic.localizedCaseInsensitiveContains("sign in") {
                throw AIAssistantError.message("Sign in to Antigravity CLI with your Google account in Terminal, then try again. Run agy using the executable selected in Settings.")
            }
            if diagnostic.contains("429") || diagnostic.localizedCaseInsensitiveContains("quota") || diagnostic.localizedCaseInsensitiveContains("usage limit") {
                throw AIAssistantError.message("Antigravity's usage limit was reached. Check your Google account allowance or try again later.")
            }
            throw AIAssistantError.message("Antigravity could not complete this request. Check your account, connection, model, and CLI version.")
        }
        // init.tools reports the CLI-wide registry, not the selected agent's allowlist.
        guard initialization?["agent"] as? String == agentName, !usedExternalTool else {
            throw AIAssistantError.message("Antigravity did not use the restricted planning agent. The document was not changed.")
        }
        guard let output = result["structured_output"] as? [String: Any] else { throw AIPlanError.format }
        return try AIPlanningContract.decode(JSONSerialization.data(withJSONObject: output, options: .sortedKeys))
    }
}
