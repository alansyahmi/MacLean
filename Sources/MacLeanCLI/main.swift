import Darwin
import Foundation

private enum CapabilityStatus: String, Codable {
    case supported
    case unsupported
    case unknown
    case experimental
}

private struct ToolAvailability: Codable {
    let name: String
    let path: String
    let status: CapabilityStatus
}

private struct Capability: Codable {
    let id: String
    let status: CapabilityStatus
    let evidence: String
}

private struct HardwareSummary: Codable {
    var modelName: String?
    var modelIdentifier: String?
    var processorName: String?
    var processorSpeed: String?
    var coreCount: String?
    var memory: String?
    var firmwareVersion: String?
    var graphicsDevices: [String]
    var graphicsMemory: String?
    var batteryCondition: String?
    var batteryCycleCount: String?
    var batteryFullChargeCapacity: String?
    var batteryChargeRemaining: String?
    var batteryStateOfCharge: String?
    var batteryVoltage: String?
    var batteryCurrent: String?
    var batteryPowerSource: String?
    var batteryChargingState: String?
    var systemThermalState: String
}

private struct DoctorReport: Codable {
    let generatedAt: String
    let operatingSystem: String
    let operatingSystemBuild: String?
    let architecture: String
    let hardware: HardwareSummary
    let systemProfilerDataTypes: [String]
    let tools: [ToolAvailability]
    let capabilities: [Capability]
}

private struct CommandResult {
    let status: Int32
    let output: String
}

private enum ProfileField {
    case modelName
    case modelIdentifier
    case processorName
    case processorSpeed
    case coreCount
    case memory
    case firmwareVersion
    case graphicsDevice
    case graphicsMemory
    case batteryCondition
    case batteryCycleCount
    case batteryFullChargeCapacity
    case batteryChargeRemaining
    case batteryStateOfCharge
    case batteryVoltage
    case batteryCurrent
    case batteryInstalled
    case batteryCharging
    case batteryFullyCharged
}

private struct ProfileFacts {
    var modelName: String?
    var modelIdentifier: String?
    var processorName: String?
    var processorSpeed: String?
    var coreCount: String?
    var memory: String?
    var firmwareVersion: String?
    var graphicsDevices: [String] = []
    var graphicsMemory: String?
    var batteryCondition: String?
    var batteryCycleCount: String?
    var batteryFullChargeCapacity: String?
    var batteryChargeRemaining: String?
    var batteryStateOfCharge: String?
    var batteryVoltage: String?
    var batteryCurrent: String?
    var batteryInstalled: String?
    var batteryCharging: String?
    var batteryFullyCharged: String?

    mutating func record(_ field: ProfileField, value: String) {
        guard let value = Self.clean(value) else { return }
        switch field {
        case .modelName: modelName = modelName ?? value
        case .modelIdentifier: modelIdentifier = modelIdentifier ?? value
        case .processorName: processorName = processorName ?? value
        case .processorSpeed: processorSpeed = processorSpeed ?? value
        case .coreCount: coreCount = coreCount ?? value
        case .memory: memory = memory ?? value
        case .firmwareVersion: firmwareVersion = firmwareVersion ?? value
        case .graphicsDevice:
            if !graphicsDevices.contains(value) { graphicsDevices.append(value) }
        case .graphicsMemory: graphicsMemory = graphicsMemory ?? value
        case .batteryCondition: batteryCondition = batteryCondition ?? value
        case .batteryCycleCount: batteryCycleCount = batteryCycleCount ?? value
        case .batteryFullChargeCapacity:
            batteryFullChargeCapacity = batteryFullChargeCapacity ?? value
        case .batteryChargeRemaining:
            batteryChargeRemaining = batteryChargeRemaining ?? value
        case .batteryStateOfCharge:
            batteryStateOfCharge = batteryStateOfCharge ?? value
        case .batteryVoltage: batteryVoltage = batteryVoltage ?? value
        case .batteryCurrent: batteryCurrent = batteryCurrent ?? value
        case .batteryInstalled: batteryInstalled = batteryInstalled ?? value
        case .batteryCharging: batteryCharging = batteryCharging ?? value
        case .batteryFullyCharged:
            batteryFullyCharged = batteryFullyCharged ?? value
        }
    }

    private static func clean(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let unavailable = ["unknown", "not available", "n/a", "null"]
        guard !unavailable.contains(trimmed.lowercased()) else { return nil }
        return trimmed
    }
}

private let allowedProfileFields: [String: ProfileField] = [
    "modelname": .modelName,
    "modelidentifier": .modelIdentifier,
    "processorname": .processorName,
    "processorspeed": .processorSpeed,
    "totalnumberofcores": .coreCount,
    "memory": .memory,
    "systemfirmwareversion": .firmwareVersion,
    "bootromversion": .firmwareVersion,
    "chipsetmodel": .graphicsDevice,
    "vramtotal": .graphicsMemory,
    "condition": .batteryCondition,
    "cyclecount": .batteryCycleCount,
    "fullchargecapacitymah": .batteryFullChargeCapacity,
    "chargeremainingmah": .batteryChargeRemaining,
    "stateofcharge": .batteryStateOfCharge,
    "voltagemv": .batteryVoltage,
    "amperagema": .batteryCurrent,
    "batteryinstalled": .batteryInstalled,
    "charging": .batteryCharging,
    "fullycharged": .batteryFullyCharged
]

private let profilerTypesToProbe = [
    "SPHardwareDataType",
    "SPDisplaysDataType",
    "SPPowerDataType",
    "SPThunderboltDataType",
    "SPiBridgeDataType",
    "SPPCIDataType"
]

private let toolPaths: [(String, String)] = [
    ("system_profiler", "/usr/sbin/system_profiler"),
    ("sysctl", "/usr/sbin/sysctl"),
    ("pmset", "/usr/bin/pmset"),
    ("powermetrics", "/usr/bin/powermetrics"),
    ("ioreg", "/usr/sbin/ioreg"),
    ("sw_vers", "/usr/bin/sw_vers"),
    ("uname", "/usr/bin/uname")
]

private func runCommand(_ path: String, arguments: [String]) -> CommandResult? {
    guard FileManager.default.isExecutableFile(atPath: path) else { return nil }

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
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return CommandResult(
            status: process.terminationStatus,
            output: String(data: data, encoding: .utf8) ?? ""
        )
    } catch {
        return nil
    }
}

private func commandValue(_ path: String, arguments: [String]) -> String? {
    guard let result = runCommand(path, arguments: arguments), result.status == 0 else {
        return nil
    }
    let value = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? nil : value
}

private func normalized(_ value: String) -> String {
    String(value.lowercased().filter { $0.isLetter || $0.isNumber })
}

private func parseProfile(_ output: String) -> ProfileFacts {
    var facts = ProfileFacts()
    for line in output.split(whereSeparator: \.isNewline) {
        guard let colon = line.firstIndex(of: ":") else { continue }
        let label = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
        let value = String(line[line.index(after: colon)...])
            .trimmingCharacters(in: .whitespaces)
        guard let field = allowedProfileFields[normalized(label)] else { continue }
        facts.record(field, value: value)
    }
    return facts
}

private func parseBatteryStatus(_ output: String) -> (source: String?, percent: String?, state: String?) {
    let source: String?
    if output.localizedCaseInsensitiveContains("AC Power") {
        source = "AC Power"
    } else if output.localizedCaseInsensitiveContains("Battery Power") {
        source = "Battery"
    } else {
        source = nil
    }

    let percent = firstMatch("([0-9]{1,3}%)", in: output)
    let state: String?
    if output.localizedCaseInsensitiveContains("discharging") {
        state = "discharging"
    } else if output.localizedCaseInsensitiveContains("charging") {
        state = "charging"
    } else if output.localizedCaseInsensitiveContains("charged") {
        state = "charged"
    } else {
        state = nil
    }
    return (source, percent, state)
}

private func firstMatch(_ pattern: String, in value: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(value.startIndex..., in: value)
    guard let match = regex.firstMatch(in: value, range: range),
          let capture = Range(match.range(at: 1), in: value) else {
        return nil
    }
    return String(value[capture])
}

private func thermalStateName() -> String {
    switch ProcessInfo.processInfo.thermalState {
    case .nominal: return "nominal"
    case .fair: return "fair"
    case .serious: return "serious"
    case .critical: return "critical"
    @unknown default: return "unknown"
    }
}

private func makeCapability(
    _ id: String,
    _ status: CapabilityStatus,
    _ evidence: String
) -> Capability {
    Capability(id: id, status: status, evidence: evidence)
}

private func buildReport() -> DoctorReport {
    let uname = commandValue("/usr/bin/uname", arguments: ["-m"]) ?? "unknown"
    let osVersion = commandValue("/usr/bin/sw_vers", arguments: ["-productVersion"])
        ?? ProcessInfo.processInfo.operatingSystemVersionString
    let osBuild = commandValue("/usr/bin/sw_vers", arguments: ["-buildVersion"])

    let availableTypesOutput = commandValue(
        "/usr/sbin/system_profiler",
        arguments: ["-listDataTypes"]
    ) ?? ""
    let availableTypes = Set(
        availableTypesOutput
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("SP") && $0.hasSuffix("DataType") }
    )
    let selectedTypes = profilerTypesToProbe.filter { availableTypes.contains($0) }

    let profilerResult: CommandResult?
    if selectedTypes.isEmpty {
        profilerResult = nil
    } else {
        profilerResult = runCommand(
            "/usr/sbin/system_profiler",
            arguments: ["-detailLevel", "mini"] + selectedTypes
        )
    }
    let profilerOutput = profilerResult?.output ?? ""
    let facts = parseProfile(profilerOutput)
    let batteryOutput = commandValue("/usr/bin/pmset", arguments: ["-g", "batt"]) ?? ""
    let batteryStatus = parseBatteryStatus(batteryOutput)
    let thermal = thermalStateName()

    let hardware = HardwareSummary(
        modelName: facts.modelName,
        modelIdentifier: facts.modelIdentifier
            ?? commandValue("/usr/sbin/sysctl", arguments: ["-n", "hw.model"]),
        processorName: facts.processorName
            ?? commandValue("/usr/sbin/sysctl", arguments: ["-n", "machdep.cpu.brand_string"]),
        processorSpeed: facts.processorSpeed,
        coreCount: facts.coreCount
            ?? commandValue("/usr/sbin/sysctl", arguments: ["-n", "hw.physicalcpu"]),
        memory: facts.memory,
        firmwareVersion: facts.firmwareVersion,
        graphicsDevices: facts.graphicsDevices.sorted(),
        graphicsMemory: facts.graphicsMemory,
        batteryCondition: facts.batteryCondition,
        batteryCycleCount: facts.batteryCycleCount,
        batteryFullChargeCapacity: facts.batteryFullChargeCapacity,
        batteryChargeRemaining: facts.batteryChargeRemaining,
        batteryStateOfCharge: facts.batteryStateOfCharge ?? batteryStatus.percent,
        batteryVoltage: facts.batteryVoltage,
        batteryCurrent: facts.batteryCurrent,
        batteryPowerSource: batteryStatus.source,
        batteryChargingState: batteryStatus.state,
        systemThermalState: thermal
    )

    let executableTools = toolPaths.map { name, path in
        ToolAvailability(
            name: name,
            path: path,
            status: FileManager.default.isExecutableFile(atPath: path) ? .supported : .unsupported
        )
    }
    let toolMap = Dictionary(uniqueKeysWithValues: executableTools.map { ($0.name, $0.status) })
    let isX86 = uname == "x86_64"
    let intelCPU = facts.processorName?.localizedCaseInsensitiveContains("Intel") == true
    let batteryPresent = facts.batteryInstalled?.localizedCaseInsensitiveContains("yes") == true
        || facts.batteryCondition != nil
        || facts.batteryCycleCount != nil
    let t2Present = profilerOutput.localizedCaseInsensitiveContains("Apple T2")
        || profilerOutput.localizedCaseInsensitiveContains("T2 Security Chip")
    let hasIBridgeFirmware = facts.firmwareVersion?.localizedCaseInsensitiveContains("iBridge") == true
    let iokitAvailable = FileManager.default.fileExists(
        atPath: "/System/Library/Frameworks/IOKit.framework"
    )
    let profilerSucceeded = profilerResult?.status == 0

    var capabilities: [Capability] = [
        makeCapability(
            "host.x86_64_architecture",
            isX86 ? .supported : (uname == "arm64" ? .unsupported : .unknown),
            "uname reports architecture \(uname); this does not identify the exact Mac model."
        ),
        makeCapability(
            "hardware.model_and_cpu_identity",
            (hardware.modelIdentifier != nil || hardware.processorName != nil) ? .supported : .unknown,
            "Uses allowlisted system_profiler and sysctl fields; unique identifiers are omitted."
        ),
        makeCapability(
            "hardware.firmware_version",
            hardware.firmwareVersion == nil ? .unknown : .supported,
            hardware.firmwareVersion == nil
                ? "A firmware version was not exposed by the selected system_profiler fields."
                : "System Profiler reported a firmware version; it is not used to infer unsupported controls."
        ),
        makeCapability(
            "graphics.inventory",
            hardware.graphicsDevices.isEmpty ? .unknown : .supported,
            hardware.graphicsDevices.isEmpty
                ? "No GPU model was exposed by the selected system_profiler fields."
                : "Reported GPU models: \(hardware.graphicsDevices.joined(separator: ", "))."
        ),
        makeCapability(
            "graphics.active_gpu_and_power",
            .unknown,
            "Inventory does not establish which GPU is active or its power state; no sampler was run."
        ),
        makeCapability(
            "cpu.frequency",
            .unknown,
            "Frequency sampling has not been probed; powermetrics was not started."
        ),
        makeCapability(
            "cpu.package_c_state_residency",
            .unknown,
            "Sampler availability and permissions are unverified for this model and OS build."
        ),
        makeCapability(
            "cpu.wakeups",
            .unknown,
            "Wakeup counters were not sampled."
        ),
        makeCapability(
            "battery.condition_and_cycles",
            batteryPresent ? .supported : .unknown,
            batteryPresent
                ? "system_profiler reported battery condition or cycle fields."
                : "Battery health fields were not exposed; absence is not treated as a failed battery."
        ),
        makeCapability(
            "battery.voltage_and_current",
            (hardware.batteryVoltage != nil && hardware.batteryCurrent != nil) ? .supported : .unknown,
            "Voltage/current fields are reported only when the selected system_profiler source exposes them."
        ),
        makeCapability(
            "battery.discharge_rate",
            .unknown,
            "A timed series is required; a single battery status is not a discharge-rate measurement."
        ),
        makeCapability(
            "background.process_energy_and_wakeups",
            .unknown,
            "No process-level power sampler was run; process names and lists are not collected."
        ),
        makeCapability(
            "thermal.system_state",
            .supported,
            "Foundation ProcessInfo reports the coarse system thermal state: \(thermal)."
        ),
        makeCapability(
            "thermal.temperatures_and_fan_speed",
            .unknown,
            "No validated physical sensor or fan source was queried."
        ),
        makeCapability(
            "thunderbolt.profiler_source",
            availableTypes.contains("SPThunderboltDataType") ? .supported : .unknown,
            availableTypes.contains("SPThunderboltDataType")
                ? "SPThunderboltDataType is available; device/controller power state is not inferred."
                : "The System Profiler data type was not listed by this macOS build."
        ),
        makeCapability(
            "thunderbolt.controller_and_device_presence",
            .unknown,
            "The read-only inventory does not normalize controller and attached-device topology yet."
        ),
        makeCapability(
            "t2.presence",
            t2Present ? .supported : .unknown,
            t2Present
                ? "The selected iBridge inventory identified an Apple T2 Security Chip."
                : (hasIBridgeFirmware
                    ? "An iBridge firmware version was reported, but no explicit Apple T2 chip label was returned; presence remains unknown."
                    : "No T2 marker was found in the selected inventory; hardware absence is not inferred.")
        ),
        makeCapability(
            "t2.general_purpose_offload",
            t2Present ? .experimental : .unknown,
            "No supported general-purpose workload interface has been established."
        ),
        makeCapability(
            "pcie.profiler_source",
            availableTypes.contains("SPPCIDataType") ? .supported : .unknown,
            availableTypes.contains("SPPCIDataType")
                ? "SPPCIDataType is available; link power states are not inferred."
                : "The System Profiler data type was not listed by this macOS build."
        ),
        makeCapability(
            "pcie.link_power_states",
            .unknown,
            "No supported read-only ASPM or link-state sampler was validated."
        ),
        makeCapability(
            "native.iokit_framework",
            iokitAvailable ? .supported : .unknown,
            iokitAvailable
                ? "The IOKit framework is present; a direct IOKit telemetry adapter is not part of this command."
                : "IOKit framework availability could not be confirmed."
        ),
        makeCapability(
            "native.system_profiler_inventory",
            profilerSucceeded ? .supported : .unknown,
            profilerSucceeded
                ? "Selected hardware data types were queried at mini detail level."
                : "The profiler query did not complete successfully or no selected data type was available."
        ),
        makeCapability(
            "native.powermetrics_utility",
            toolMap["powermetrics"] ?? .unknown,
            (toolMap["powermetrics"] == .supported)
                ? "Installed; sampler support and access were not tested."
                : "Utility availability could not be confirmed."
        ),
        makeCapability(
            "native.pmset",
            toolMap["pmset"] ?? .unknown,
            (toolMap["pmset"] == .supported)
                ? "Installed; only the read-only battery status query is used."
                : "Utility availability could not be confirmed."
        ),
        makeCapability(
            "native.ioreg",
            toolMap["ioreg"] ?? .unknown,
            (toolMap["ioreg"] == .supported)
                ? "Installed; IORegistry trees and unique device identifiers were not collected."
                : "Utility availability could not be confirmed."
        )
    ]

    if intelCPU {
        capabilities.append(makeCapability(
            "cpu.vendor_identity",
            .supported,
            "The reported processor name contains Intel."
        ))
    } else if isX86 {
        capabilities.append(makeCapability(
            "cpu.vendor_identity",
            .unknown,
            "The host is x86_64, but the processor name was not exposed."
        ))
    } else {
        capabilities.append(makeCapability(
            "cpu.vendor_identity",
            isX86 ? .unknown : .unsupported,
            "MacLean's initial target is an Intel Mac."
        ))
    }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return DoctorReport(
        generatedAt: formatter.string(from: Date()),
        operatingSystem: "macOS \(osVersion)",
        operatingSystemBuild: osBuild,
        architecture: uname,
        hardware: hardware,
        systemProfilerDataTypes: selectedTypes,
        tools: executableTools,
        capabilities: capabilities
    )
}

private func printHumanReport(_ report: DoctorReport) {
    print("MacLean Doctor")
    print("OS: \(report.operatingSystem)\(report.operatingSystemBuild.map { " (build \($0))" } ?? "")")
    print("Architecture: \(report.architecture)")
    print()

    print("Hardware inventory")
    print("  Model: \(report.hardware.modelName ?? "unknown")")
    print("  Model identifier: \(report.hardware.modelIdentifier ?? "unknown")")
    print("  Processor: \(report.hardware.processorName ?? "unknown")")
    print("  Processor speed (reported): \(report.hardware.processorSpeed ?? "unavailable")")
    print("  Cores: \(report.hardware.coreCount ?? "unavailable")")
    print("  Memory: \(report.hardware.memory ?? "unavailable")")
    print("  Firmware: \(report.hardware.firmwareVersion ?? "unavailable")")
    print("  Graphics: \(report.hardware.graphicsDevices.isEmpty ? "unknown" : report.hardware.graphicsDevices.joined(separator: ", "))")
    if let graphicsMemory = report.hardware.graphicsMemory {
        print("  Graphics memory (reported): \(graphicsMemory)")
    }
    print("  Battery condition: \(report.hardware.batteryCondition ?? "unavailable")")
    print("  Battery cycles: \(report.hardware.batteryCycleCount ?? "unavailable")")
    print("  Full charge capacity: \(report.hardware.batteryFullChargeCapacity ?? "unavailable")")
    print("  Battery voltage/current: \(report.hardware.batteryVoltage ?? "unavailable") / \(report.hardware.batteryCurrent ?? "unavailable")")
    print("  Power source: \(report.hardware.batteryPowerSource ?? "unknown")")
    if let charge = report.hardware.batteryStateOfCharge {
        print("  State of charge (OS status): \(charge)")
    }
    if let charging = report.hardware.batteryChargingState {
        print("  Battery state: \(charging)")
    }
    print("  System thermal state: \(report.hardware.systemThermalState) (coarse OS signal)")
    print()

    print("Available power and inventory tools")
    for tool in report.tools {
        print("  [\(tool.status.rawValue.uppercased())] \(tool.name) — \(tool.path)")
    }
    print()

    print("Capability matrix")
    for capability in report.capabilities {
        print("  [\(capability.status.rawValue.uppercased())] \(capability.id) — \(capability.evidence)")
    }
    print()
    print("Read-only: no settings changed; no privileged sampling or raw device tree output was collected.")
}

private func printUsage() {
    print("""
    Usage:
      swift run maclean doctor [--json]

    doctor performs a one-shot, read-only hardware and interface inventory.
    """)
}

private func main() {
    let arguments = Array(CommandLine.arguments.dropFirst())
    if arguments.isEmpty || arguments == ["--help"] || arguments == ["-h"] {
        printUsage()
        exit(arguments.isEmpty ? EXIT_FAILURE : EXIT_SUCCESS)
    }

    guard arguments.first == "doctor" else {
        fputs("Unknown command. Available command: doctor\n", stderr)
        printUsage()
        exit(EXIT_FAILURE)
    }

    let remaining = Array(arguments.dropFirst())
    guard remaining.isEmpty || remaining == ["--json"] else {
        fputs("Unsupported doctor option.\n", stderr)
        printUsage()
        exit(EXIT_FAILURE)
    }

    let report = buildReport()
    if remaining == ["--json"] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(report)
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data([0x0A]))
        } catch {
            fputs("Could not encode the doctor report.\n", stderr)
            exit(EXIT_FAILURE)
        }
    } else {
        printHumanReport(report)
    }
}

main()
