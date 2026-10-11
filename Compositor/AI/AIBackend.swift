import Foundation

nonisolated protocol AIBackend: Sendable {
    func plan(prompt: String, preview: Data?) throws -> AIEditPlan
    func cancel()
}

nonisolated enum AIBackendProvider: String, CaseIterable, Identifiable, Sendable {
    case codex, gemini
    var id: String { rawValue }
    var title: String { self == .codex ? "Codex" : "Gemini CLI" }
    var accountName: String { self == .codex ? "Codex" : "Gemini" }
    var pathPlaceholder: String { self == .codex ? "Optional Codex executable path" : "Optional Gemini executable path" }
    var loginInstructions: String {
        self == .codex
            ? "Use your own Codex login. Install Codex CLI and run codex login, or sign in to the Codex desktop app."
            : "Install Gemini CLI 0.63.0 or later and authenticate in Terminal. Google sign-in may reject this client; Gemini API Key uses separate API quotas and billing."
    }
    func findExecutable(customPath: String = "") -> URL? {
        let bundled = self == .codex ? [
            "/Applications/Codex.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex",
            "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex"
        ] : []
        return AIExecutableLocator.find(rawValue, customPath: customPath, additional: bundled)
    }
    func backend(executable: URL, model: String = "", onStatus: @escaping @Sendable (String) -> Void = { _ in }) -> any AIBackend {
        switch self {
        case .codex: AICodexBackend(executable: executable)
        case .gemini: AIGeminiCLIBackend(executable: executable, model: model, onStatus: onStatus)
        }
    }
}

nonisolated enum AIExecutableLocator {
    static var nodeDirectories: [String] {
        let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".nvm/versions/node")
        let versions = (try? FileManager.default.contentsOfDirectory(atPath: root.path)) ?? []
        return versions.sorted { $0.compare($1, options: .numeric) == .orderedDescending }
            .map { root.appendingPathComponent($0).appendingPathComponent("bin").path }
    }
    static func find(_ name: String, customPath: String = "", additional: [String] = []) -> URL? {
        let custom = (customPath.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).expandingTildeInPath
        if !custom.isEmpty { return executable(custom) }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let standard = ["/opt/homebrew/bin", "/usr/local/bin"].map { $0 + "/" + name }
        let directories = [home + "/.local/bin", home + "/.npm-global/bin"]
            + (ProcessInfo.processInfo.environment["PATH"] ?? "").split(separator: ":").map(String.init)
            + nodeDirectories
        return (standard + additional + directories.map { $0 + "/" + name }).compactMap(executable).first
    }
    private static func executable(_ path: String) -> URL? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), !isDirectory.boolValue,
              FileManager.default.isExecutableFile(atPath: path) else { return nil }
        return URL(fileURLWithPath: path)
    }
    static func environment(for executable: URL) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let directories = [executable.deletingLastPathComponent().path, "/opt/homebrew/bin", "/usr/local/bin"]
            + nodeDirectories + [environment["PATH"] ?? "/usr/bin:/bin"]
        environment["PATH"] = directories.joined(separator: ":")
        return environment
    }
}
