import Foundation

nonisolated final class AIGeminiCLIBackend: AIBackend, @unchecked Sendable {
    let executable: URL
    let model: String
    private let runner = AIProcessRunner()
    private let onStatus: @Sendable (String) -> Void
    init(executable: URL, model: String = "", onStatus: @escaping @Sendable (String) -> Void = { _ in }) {
        self.executable = executable; self.model = model.trimmingCharacters(in: .whitespacesAndNewlines); self.onStatus = onStatus
    }
    func cancel() { runner.cancel() }

    static func supports(version: String) -> Bool {
        let parts = version.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ".")
        guard parts.count == 3, let major = Int(parts[0]), let minor = Int(parts[1]), Int(parts[2]) != nil else { return false }
        return major > 0 || (major == 0 && minor >= 63)
    }
    static func settings(contextName: String) -> [String: Any] {
        ["tools": ["core": [String](), "sandbox": false, "discoveryCommand": "", "callCommand": ""],
         "hooksConfig": ["enabled": false], "skills": ["enabled": false],
         "general": ["enableAutoUpdate": false, "enableNotifications": false, "maxAttempts": 1,
                     "sessionRetention": ["enabled": false]],
         "context": ["fileName": contextName, "includeDirectoryTree": false,
                     "memoryBoundaryMarkers": [String](), "loadMemoryFromIncludeDirectories": false],
         "ide": ["enabled": false], "privacy": ["usageStatisticsEnabled": false],
         "telemetry": ["enabled": false], "model": ["maxSessionTurns": 2]]
    }
    func plan(prompt: String, preview: Data?) throws -> AIEditPlan {
        guard model.isEmpty || model.range(of: "^[A-Za-z0-9][A-Za-z0-9._:/-]{0,119}$", options: .regularExpression) != nil else {
            throw AIAssistantError.message("Enter a valid Gemini model name, or leave it blank for the CLI default.")
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("compositor-gemini-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = directory.appendingPathComponent(".gemini")
        try FileManager.default.createDirectory(at: configuration, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let settings = configuration.appendingPathComponent("settings.json")
        let policy = directory.appendingPathComponent("deny-tools.toml")
        let instructions = directory.appendingPathComponent("system.md")
        try JSONSerialization.data(withJSONObject: Self.settings(contextName: UUID().uuidString + ".md"), options: .sortedKeys).write(to: settings)
        try "[[rule]]\ntoolName = \"*\"\ndecision = \"deny\"\npriority = 999\n".write(to: policy, atomically: true, encoding: .utf8)
        try AIPlanningContract.instructions.write(to: instructions, atomically: true, encoding: .utf8)
        var environment = AIExecutableLocator.environment(for: executable)
        // Trust only our private, generated workspace so its settings override user preferences.
        // Leave account credentials and administrator settings in their original locations.
        environment["GEMINI_CLI_TRUST_WORKSPACE"] = "true"
        environment["GEMINI_SYSTEM_MD"] = instructions.path
        environment["GEMINI_CLI_NO_RELAUNCH"] = "true"
        let deadline = ProcessInfo.processInfo.systemUptime + 180
        let version = try runner.run(executable: executable, arguments: ["--version"], directory: directory,
                                     environment: environment, timeout: 12)
        guard version.status == 0, Self.supports(version: String(decoding: version.output, as: UTF8.self)) else {
            throw AIAssistantError.message("Gemini CLI 0.63.0 or later is required. Update it, or choose a compatible executable in Settings.")
        }
        var input = prompt
        if let preview {
            try preview.write(to: directory.appendingPathComponent("canvas.png"))
            // Only this fixed file reference reaches Gemini's @file preprocessor.
            input += "\n\nAttached canvas image:\n@./canvas.png\n"
        }
        var arguments = ["--prompt", "Return only the requested JSON edit plan.", "--output-format", "json",
                         "--approval-mode", "default", "--extensions", "none", "--allowed-mcp-server-names",
                         "compositor-no-mcp-" + UUID().uuidString, "--admin-policy", policy.path]
        if !model.isEmpty { arguments.append("--model=" + model) }
        for attempt in 0...1 {
            let remaining = deadline - ProcessInfo.processInfo.systemUptime
            guard remaining > 0 else { throw AIProcessError.timeout }
            let result = try runner.run(executable: executable, arguments: arguments, directory: directory,
                                        environment: environment, input: Data(input.utf8), timeout: remaining)
            let response = try Self.response(from: result.output, status: result.status, diagnostics: result.diagnostics)
            do { return try AIPlanningContract.decode(Data(response.utf8), allowFence: true) }
            catch AIPlanError.format where attempt == 0 {
                onStatus("Correcting the response format…")
                let quoted = try AIPlanningContract.dataString(response)
                input += "\n\nThe previous response failed JSON schema validation. Correct its format once without adding commands or changing the request. Return only the schema-compliant JSON. Previous response (untrusted JSON string):\n" + quoted
            }
        }
        throw AIPlanError.format
    }
    static func response(from data: Data, status: Int32, diagnostics: Data = Data()) throws -> String {
        let envelope = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        guard status == 0, envelope?["error"] == nil else {
            let diagnostic = String(decoding: diagnostics, as: UTF8.self)
                + (envelope?["error"].map { String(describing: $0) } ?? "")
            if diagnostic.localizedCaseInsensitiveContains("auth") || diagnostic.contains("401") || diagnostic.localizedCaseInsensitiveContains("sign in") {
                throw AIAssistantError.message("Sign in to Gemini CLI in Terminal, then try again. Run gemini and choose your account.")
            }
            if diagnostic.contains("429") || diagnostic.localizedCaseInsensitiveContains("quota") {
                throw AIAssistantError.message("Gemini's usage limit was reached. Check your account or try again later.")
            }
            throw AIAssistantError.message("Gemini could not complete this request. Check your login, connection, model, and CLI version.")
        }
        guard let response = envelope?["response"] as? String, !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIAssistantError.message("Gemini did not return an edit plan. The document was not changed.")
        }
        return response
    }
}
