import Foundation
import Darwin

nonisolated enum AIProcessError: LocalizedError {
    case timeout, outputLimit
    var errorDescription: String? {
        switch self {
        case .timeout: L("AI did not finish within the time limit. The document was not changed.")
        case .outputLimit: L("AI returned too much output. The document was not changed.")
        }
    }
}

/// A runner belongs to one request, including its optional format correction.
nonisolated final class AIProcessRunner: @unchecked Sendable {
    struct Result: Sendable { let status: Int32; let output: Data; let diagnostics: Data }
    private let lock = NSLock()
    private var running: Process?
    private var ownsGroup = false
    private var canceled = false

    func cancel() {
        lock.lock(); defer { lock.unlock() }
        canceled = true
        if let running, running.isRunning { signal(running, force: false) }
    }
    private var isCanceled: Bool {
        lock.lock(); defer { lock.unlock() }
        return canceled || Task.isCancelled
    }
    private func signal(_ process: Process, force: Bool) {
        let pid = process.processIdentifier
        guard pid > 1 else { return }
        _ = Darwin.kill(ownsGroup ? -pid : pid, force ? SIGKILL : SIGTERM)
    }
    private func stop(_ process: Process) {
        lock.lock(); signal(process, force: false); lock.unlock()
        let deadline = ProcessInfo.processInfo.systemUptime + 0.8
        while process.isRunning && ProcessInfo.processInfo.systemUptime < deadline { Thread.sleep(forTimeInterval: 0.02) }
        if process.isRunning {
            lock.lock(); signal(process, force: true); lock.unlock()
        }
        process.waitUntilExit()
    }
    func run(executable: URL, arguments: [String], directory: URL, environment: [String: String],
             input: Data = Data(), timeout: TimeInterval, outputLimit: Int = 1_024_000) throws -> Result {
        let prefix = directory.appendingPathComponent(UUID().uuidString).path
        let paths = [prefix + ".in", prefix + ".out", prefix + ".err"].map { URL(fileURLWithPath: $0) }
        try input.write(to: paths[0], options: .atomic)
        for path in paths.dropFirst() { FileManager.default.createFile(atPath: path.path, contents: nil) }
        for path in paths { try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: path.path) }
        defer { for path in paths { try? FileManager.default.removeItem(at: path) } }
        let stdin = try FileHandle(forReadingFrom: paths[0])
        let stdout = try FileHandle(forWritingTo: paths[1])
        let stderr = try FileHandle(forWritingTo: paths[2])
        defer { try? stdin.close(); try? stdout.close(); try? stderr.close() }
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = directory
        process.environment = environment
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr
        lock.lock()
        guard !canceled else { lock.unlock(); throw CancellationError() }
        do {
            try process.run()
            running = process
            ownsGroup = getpgid(process.processIdentifier) == process.processIdentifier
            lock.unlock()
        } catch { lock.unlock(); throw error }
        defer { lock.lock(); running = nil; ownsGroup = false; lock.unlock() }
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        func oversized() -> Bool {
            paths.dropFirst().contains { path in
                let attributes = try? FileManager.default.attributesOfItem(atPath: path.path)
                return ((attributes?[.size] as? NSNumber)?.intValue ?? 0) > outputLimit
            }
        }
        while process.isRunning {
            if isCanceled { stop(process); throw CancellationError() }
            if oversized() { stop(process); throw AIProcessError.outputLimit }
            if ProcessInfo.processInfo.systemUptime >= deadline { stop(process); throw AIProcessError.timeout }
            Thread.sleep(forTimeInterval: 0.03)
        }
        process.waitUntilExit()
        if isCanceled { throw CancellationError() }
        if oversized() { throw AIProcessError.outputLimit }
        return Result(status: process.terminationStatus, output: try Data(contentsOf: paths[1]),
                      diagnostics: try Data(contentsOf: paths[2]))
    }
}
