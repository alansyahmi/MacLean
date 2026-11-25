import Foundation
import MacLeanCore
import MacLeanPlatformMacOS

private func printUsage() {
    print("""
    Usage:
      maclean doctor [--json]
      maclean monitor [--interval SECONDS] [--count SAMPLES]
      maclean benchmark run --scenario NAME [options]
      maclean benchmark compare BASELINE.json CANDIDATE.json

    doctor performs a one-shot, read-only hardware and interface inventory.
    monitor emits local JSON Lines telemetry; press Ctrl-C to stop an unbounded run.
    benchmark scenarios: desktop-idle, screen-off-idle, light-productivity,
    video-playback, cpu-intensive. The workload is performed by the user.
    Optional powermetrics sampling requires an already privileged process; MacLean
    never requests a password or elevates itself.
    """)
}

private func runBenchmark(_ arguments: [String]) {
    guard let action = arguments.first else {
        fputs("Missing benchmark action. Use run or compare.\n", stderr)
        printUsage()
        exit(EXIT_FAILURE)
    }
    switch action {
    case "run":
        runBenchmarkTrial(Array(arguments.dropFirst()))
    case "compare":
        compareBenchmarks(Array(arguments.dropFirst()))
    default:
        fputs("Unsupported benchmark action: \(action).\n", stderr)
        printUsage()
        exit(EXIT_FAILURE)
    }
}

private func runBenchmarkTrial(_ arguments: [String]) {
    var scenario: BenchmarkScenario?
    var duration: Double?
    var interval = 5.0
    var repetitions = 3
    var warmup = 0.0
    var workload: String?
    var taskCompletion: Double?
    var outputPath: String?
    var includePowermetrics = false
    var index = 0

    while index < arguments.count {
        let option = arguments[index]
        if option == "--powermetrics" {
            includePowermetrics = true
            index += 1
            continue
        }
        guard index + 1 < arguments.count else {
            fputs("Missing value for \(option).\n", stderr)
            exit(EXIT_FAILURE)
        }
        let value = arguments[index + 1]
        switch option {
        case "--scenario": scenario = BenchmarkScenario(rawValue: value)
        case "--duration": duration = Double(value)
        case "--interval":
            guard let parsed = Double(value), (1...60).contains(parsed) else {
                fputs("Interval must be between 1 and 60 seconds.\n", stderr)
                exit(EXIT_FAILURE)
            }
            interval = parsed
        case "--repetitions":
            guard let parsed = Int(value), (1...20).contains(parsed) else {
                fputs("Repetitions must be between 1 and 20.\n", stderr)
                exit(EXIT_FAILURE)
            }
            repetitions = parsed
        case "--warmup-seconds":
            guard let parsed = Double(value), (0...3_600).contains(parsed) else {
                fputs("Warm-up must be between 0 and 3600 seconds.\n", stderr)
                exit(EXIT_FAILURE)
            }
            warmup = parsed
        case "--workload": workload = value
        case "--task-completion-seconds":
            guard let parsed = Double(value), parsed > 0 else {
                fputs("Task completion time must be positive.\n", stderr)
                exit(EXIT_FAILURE)
            }
            taskCompletion = parsed
        case "--output": outputPath = value
        default:
            fputs("Unsupported benchmark option: \(option).\n", stderr)
            exit(EXIT_FAILURE)
        }
        index += 2
    }

    guard let scenario else {
        fputs("A supported --scenario is required.\n", stderr)
        exit(EXIT_FAILURE)
    }
    let targetDuration = duration ?? scenario.suggestedDurationSeconds
    guard let targetDuration, (1...86_400).contains(targetDuration) else {
        fputs("This scenario requires --duration between 1 and 86400 seconds.\n", stderr)
        exit(EXIT_FAILURE)
    }
    if scenario != .desktopIdle, workload?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
        fputs("This scenario requires --workload to record the task and conditions being measured.\n", stderr)
        exit(EXIT_FAILURE)
    }
    if scenario == .cpuIntensive, taskCompletion == nil {
        fputs("cpu-intensive requires --task-completion-seconds for the fixed task result.\n", stderr)
        exit(EXIT_FAILURE)
    }
    if includePowermetrics, let error = MacLeanPowermetricsCollector.authorizationError {
        fputs("Privileged powermetrics was requested, but not started: \(error)\n", stderr)
        exit(EXIT_FAILURE)
    }

    let configuration = BenchmarkConfiguration(
        scenario: scenario,
        durationSeconds: targetDuration,
        intervalSeconds: interval,
        repetitions: repetitions,
        warmupSeconds: warmup,
        workloadDescription: workload,
        taskCompletionSeconds: taskCompletion,
        includePowermetrics: includePowermetrics
    )
    do {
        let result = try MacLeanBenchmarkRunner.run(configuration: configuration) { trial, elapsed, total in
            fputs(String(format: "Trial %d: %.0f / %.0f seconds\n", trial, elapsed, total), stderr)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(result)
        if let outputPath {
            let outputURL = URL(fileURLWithPath: outputPath).standardizedFileURL
            try data.write(to: outputURL, options: [.atomic])
            fputs("Benchmark result saved to \(outputURL.path)\n", stderr)
        } else {
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data([0x0A]))
        }
    } catch {
        fputs("Benchmark failed: \(error)\n", stderr)
        exit(EXIT_FAILURE)
    }
}

private func compareBenchmarks(_ arguments: [String]) {
    guard arguments.count == 2 else {
        fputs("Provide a baseline and candidate JSON result.\n", stderr)
        exit(EXIT_FAILURE)
    }
    do {
        let baseline = try JSONDecoder().decode(BenchmarkResult.self, from: Data(contentsOf: URL(fileURLWithPath: arguments[0])))
        let candidate = try JSONDecoder().decode(BenchmarkResult.self, from: Data(contentsOf: URL(fileURLWithPath: arguments[1])))
        if let reason = BenchmarkCompatibility.incompatibilityReason(
            baseline: baseline,
            candidate: candidate
        ) {
            fputs("Runs are not comparable: \(reason)\n", stderr)
            exit(EXIT_FAILURE)
        }
        let comparison = BenchmarkComparison(baseline: baseline, candidate: candidate)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        FileHandle.standardOutput.write(try encoder.encode(comparison))
        FileHandle.standardOutput.write(Data([0x0A]))
    } catch {
        fputs("Could not read benchmark results: \(error)\n", stderr)
        exit(EXIT_FAILURE)
    }
}

private func main() {
    let arguments = Array(CommandLine.arguments.dropFirst())
    guard let command = arguments.first else {
        printUsage()
        exit(EXIT_FAILURE)
    }

    switch command {
    case "--help", "-h":
        printUsage()
    case "doctor":
        let remaining = Array(arguments.dropFirst())
        guard remaining.isEmpty || remaining == ["--json"] else {
            fputs("Unsupported doctor option.\n", stderr)
            printUsage()
            exit(EXIT_FAILURE)
        }
        guard MacLeanDoctor.run(json: remaining == ["--json"]) else { exit(EXIT_FAILURE) }
    case "monitor":
        var interval = 5.0
        var count: Int?
        var index = 1
        while index < arguments.count {
            let option = arguments[index]
            guard index + 1 < arguments.count else {
                fputs("Missing value for \(option).\n", stderr)
                printUsage()
                exit(EXIT_FAILURE)
            }
            let value = arguments[index + 1]
            switch option {
            case "--interval":
                guard let parsed = Double(value), parsed >= 1, parsed <= 3600 else {
                    fputs("Interval must be between 1 and 3600 seconds.\n", stderr)
                    exit(EXIT_FAILURE)
                }
                interval = parsed
            case "--count":
                guard let parsed = Int(value), parsed > 0 else {
                    fputs("Count must be a positive integer.\n", stderr)
                    exit(EXIT_FAILURE)
                }
                count = parsed
            default:
                fputs("Unsupported monitor option: \(option).\n", stderr)
                printUsage()
                exit(EXIT_FAILURE)
            }
            index += 2
        }
        MacLeanMonitor.run(intervalSeconds: interval, count: count)
    case "benchmark":
        runBenchmark(Array(arguments.dropFirst()))
    default:
        fputs("Unknown command. Available commands: doctor, monitor, benchmark\n", stderr)
        printUsage()
        exit(EXIT_FAILURE)
    }
}

main()
