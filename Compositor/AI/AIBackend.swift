import Foundation

nonisolated protocol AIBackend: Sendable {
    func plan(prompt: String, preview: Data?) throws -> AIEditPlan
    func cancel()
}

nonisolated enum AIBackendProvider: String, CaseIterable, Identifiable, Sendable {
    case codex, gemini, antigravity
    var id: String { rawValue }
    var supportsCanvasImage: Bool { self != .antigravity }
    var title: String {
        switch self {
        case .codex: "Codex"
        case .gemini: "Gemini CLI"
        case .antigravity: "Antigravity CLI"
        }
    }
    var accountName: String { self == .antigravity ? "Google / Antigravity" : (self == .codex ? "Codex" : "Gemini") }
    var pathPlaceholder: String {
        switch self {
        case .codex: "Optional Codex executable path"
        case .gemini: "Optional Gemini executable path"
        case .antigravity: "Optional Antigravity executable path"
        }
    }
    var loginInstructions: String {
        switch self {
        case .codex: "Use your own Codex login. Install Codex CLI and run codex login, or sign in to the Codex desktop app."
        case .gemini: "Install Gemini CLI 0.63.0 or later and authenticate in Terminal. Google sign-in may reject this client; Gemini API Key uses separate API quotas and billing."
        case .antigravity: "Install Antigravity CLI and run agy in Terminal to sign in with your Google account. The app uses that CLI's saved login and account allowance."
        }
    }
    func findExecutable(customPath: String = "") -> URL? {
        let bundled = self == .codex ? [
            "/Applications/Codex.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex",
            "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex"
        ] : []
        return AIExecutableLocator.find(self == .antigravity ? "agy" : rawValue, customPath: customPath, additional: bundled)
    }
    func backend(executable: URL, model: String = "", onStatus: @escaping @Sendable (String) -> Void = { _ in }) -> any AIBackend {
        switch self {
        case .codex: AICodexBackend(executable: executable)
        case .gemini: AIGeminiCLIBackend(executable: executable, model: model, onStatus: onStatus)
        case .antigravity: AIAntigravityCLIBackend(executable: executable, model: model)
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
        // Native CLI children must load their own libraries, not the editor's or Xcode's injected test libraries.
        for key in environment.keys.filter({ $0.hasPrefix("DYLD_") || $0.hasPrefix("__XPC_DYLD_") || $0.hasPrefix("XCInject") }) {
            environment.removeValue(forKey: key)
        }
        let directories = [executable.deletingLastPathComponent().path, "/opt/homebrew/bin", "/usr/local/bin"]
            + nodeDirectories + [environment["PATH"] ?? "/usr/bin:/bin"]
        environment["PATH"] = directories.joined(separator: ":")
        return environment
    }
}
