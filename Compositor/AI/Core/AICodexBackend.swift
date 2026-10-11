import Foundation

/// Uses each user's local Codex credentials; only JSON planning runs in the child process.
nonisolated final class AICodexBackend: AIBackend, @unchecked Sendable {
    private let lock = NSLock()
    private var running: Process?
    private var canceled = false
    let executable: URL

    static func findExecutable(customPath: String = "") -> URL? {
        AIBackendProvider.codex.findExecutable(customPath: customPath)
    }

    init(executable: URL) { self.executable = executable }

    func cancel() {
        lock.lock()
        canceled = true
        if let running, running.isRunning { running.terminate() }
        lock.unlock()
    }

    private var isCanceled: Bool {
        lock.lock(); defer { lock.unlock() }
        return canceled || Task.isCancelled
    }

    func plan(prompt: String, preview: Data?) throws -> AIEditPlan {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("compositor-ai-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let schema = directory.appendingPathComponent("schema.json")
        try AIPlanningContract.schema().write(to: schema)
        let output = directory.appendingPathComponent("result.json")
        let log = directory.appendingPathComponent("events.log")
        FileManager.default.createFile(atPath: log.path, contents: nil)
        let handle = try FileHandle(forWritingTo: log)
        defer { try? handle.close() }
        let process = Process()
        process.executableURL = executable
        process.environment = AIExecutableLocator.environment(for: executable)
        process.arguments = ["exec", "--ignore-user-config", "--skip-git-repo-check", "--ephemeral", "--sandbox", "read-only",
            "--disable", "shell_tool", "--disable", "apps", "--disable", "computer_use", "--disable", "browser_use",
            "--disable", "plugins", "--disable", "multi_agent", "-c", "web_search=\"disabled\"",
            "--cd", directory.path, "--output-schema", schema.path, "--output-last-message", output.path, "--json", "-"]
        if let preview {
            let image = directory.appendingPathComponent("canvas.png")
            try preview.write(to: image)
            process.arguments!.insert(contentsOf: ["--image", image.path], at: process.arguments!.count - 1)
        }
        let input = Pipe()
        process.standardInput = input
        process.standardOutput = handle
        process.standardError = handle
        lock.lock()
        guard !canceled else { lock.unlock(); throw CancellationError() }
        do { try process.run(); running = process; lock.unlock() }
        catch { lock.unlock(); throw error }
        defer { lock.lock(); running = nil; lock.unlock() }
        try input.fileHandleForWriting.write(contentsOf: Data(prompt.utf8))
        try input.fileHandleForWriting.close()
        let deadline = Date().addingTimeInterval(180)
        while process.isRunning && Date() < deadline && !isCanceled { Thread.sleep(forTimeInterval: 0.1) }
        if isCanceled {
            if process.isRunning { process.terminate() }
            process.waitUntilExit()
            throw CancellationError()
        }
        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
            throw AIAssistantError.message("AI timed out after 3 minutes. The document was not changed.")
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0, let data = try? Data(contentsOf: output), data.count <= 256_000 else {
            let logs = (try? String(contentsOf: log, encoding: .utf8)) ?? ""
            if logs.localizedCaseInsensitiveContains("not logged in") || logs.contains("401") || logs.localizedCaseInsensitiveContains("authentication") {
                throw AIAssistantError.message("Sign in to Codex on this Mac, then try again. In Terminal: codex login")
            }
            if logs.contains("unexpected argument") || logs.contains("unknown variant") {
                throw AIAssistantError.message("Update Codex CLI to a current version, or select the bundled CLI in Settings.")
            }
            throw AIAssistantError.message(LF("Codex could not complete this request (exit %d). Check your login, connection, and usage limit.", process.terminationStatus))
        }
        return try AIPlanningContract.decode(data)
    }

}
