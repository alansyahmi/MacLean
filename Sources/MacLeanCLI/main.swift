import Foundation
import MacLeanPlatformMacOS

private func printUsage() {
    print("""
    Usage:
      swift run maclean doctor [--json]
      swift run maclean monitor [--interval SECONDS] [--count SAMPLES]

    doctor performs a one-shot, read-only hardware and interface inventory.
    monitor emits local JSON Lines telemetry; press Ctrl-C to stop an unbounded run.
    """)
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
    default:
        fputs("Unknown command. Available commands: doctor, monitor\n", stderr)
        printUsage()
        exit(EXIT_FAILURE)
    }
}

main()
