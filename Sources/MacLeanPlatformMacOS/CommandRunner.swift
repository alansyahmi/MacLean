import Darwin
import Foundation

struct ProcessResult {
    let status: Int32
    let output: String
}

private final class ProcessOutputReader: @unchecked Sendable {
    private let fileHandle: FileHandle
    private let lock = NSLock()
    private let finished = DispatchSemaphore(value: 0)
    private var output = Data()

    init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }

    func start() {
        DispatchQueue.global(qos: .utility).async { [self] in
            let captured = fileHandle.readDataToEndOfFile()
            lock.lock()
            output = captured
            lock.unlock()
            finished.signal()
        }
    }

    func read(timeoutSeconds: TimeInterval) -> Data? {
        guard finished.wait(timeout: .now() + timeoutSeconds) == .success else { return nil }
        lock.lock()
        defer { lock.unlock() }
        return output
    }
}

enum CommandRunner {
    static func run(
        _ path: String,
        arguments: [String],
        timeoutSeconds: TimeInterval = 20
    ) -> ProcessResult? {
        guard FileManager.default.isExecutableFile(atPath: path), timeoutSeconds > 0 else {
            return nil
        }

        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = FileHandle.nullDevice

        var childEnvironment = ProcessInfo.processInfo.environment
        childEnvironment["LC_ALL"] = "C"
        process.environment = childEnvironment

        do {
            try process.run()
        } catch {
            return nil
        }
        let outputReader = ProcessOutputReader(fileHandle: outputPipe.fileHandleForReading)
        outputReader.start()

        let deadline = DispatchTime.now().uptimeNanoseconds
            + UInt64(timeoutSeconds * 1_000_000_000)
        wait(for: process, until: deadline)
        let timedOut = process.isRunning
        if timedOut {
            process.terminate()
            wait(for: process, until: DispatchTime.now().uptimeNanoseconds + 500_000_000)
            if process.isRunning {
                _ = Darwin.kill(pid_t(process.processIdentifier), SIGKILL)
            }
        }
        process.waitUntilExit()

        guard !timedOut,
              let data = outputReader.read(timeoutSeconds: 1) else { return nil }
        return ProcessResult(
            status: process.terminationStatus,
            output: String(data: data, encoding: .utf8) ?? ""
        )
    }

    static func value(
        _ path: String,
        arguments: [String],
        timeoutSeconds: TimeInterval = 20
    ) -> String? {
        guard let result = run(path, arguments: arguments, timeoutSeconds: timeoutSeconds),
              result.status == 0 else {
            return nil
        }
        let value = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private static func wait(for process: Process, until deadline: UInt64) {
        while process.isRunning && DispatchTime.now().uptimeNanoseconds < deadline {
            Thread.sleep(forTimeInterval: 0.02)
        }
    }
}
