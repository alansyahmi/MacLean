import Foundation
import MacLeanCore

func thermalStateName() -> String {
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
    let uname = CommandRunner.value("/usr/bin/uname", arguments: ["-m"]) ?? "unknown"
    let osVersion = CommandRunner.value("/usr/bin/sw_vers", arguments: ["-productVersion"])
        ?? ProcessInfo.processInfo.operatingSystemVersionString
    let osBuild = CommandRunner.value("/usr/bin/sw_vers", arguments: ["-buildVersion"])

    let availableTypesOutput = CommandRunner.value(
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

    let profilerResult: ProcessResult?
    if selectedTypes.isEmpty {
        profilerResult = nil
    } else {
        profilerResult = CommandRunner.run(
            "/usr/sbin/system_profiler",
            arguments: ["-detailLevel", "mini"] + selectedTypes
        )
    }
    let profilerOutput = profilerResult?.output ?? ""
    let facts = parseProfile(profilerOutput)
    let batteryOutput = CommandRunner.value("/usr/bin/pmset", arguments: ["-g", "batt"]) ?? ""
    let batteryStatus = parseBatteryStatus(batteryOutput)
    let thermal = thermalStateName()

    let hardware = HardwareSummary(
        modelName: facts.modelName,
        modelIdentifier: facts.modelIdentifier
            ?? CommandRunner.value("/usr/sbin/sysctl", arguments: ["-n", "hw.model"]),
        processorName: facts.processorName
            ?? CommandRunner.value("/usr/sbin/sysctl", arguments: ["-n", "machdep.cpu.brand_string"]),
        processorSpeed: facts.processorSpeed,
        coreCount: facts.coreCount
            ?? CommandRunner.value("/usr/sbin/sysctl", arguments: ["-n", "hw.physicalcpu"]),
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
            "A non-privileged powermetrics attempt on the validation host required superuser access; per-sample frequency was not obtained."
        ),
        makeCapability(
            "cpu.package_c_state_residency",
            .unknown,
            "A non-privileged powermetrics attempt on the validation host required superuser access; residency data was not obtained."
        ),
        makeCapability(
            "cpu.wakeups",
            .unknown,
            "Wakeup counters were not sampled; the non-privileged powermetrics attempt required superuser access on the validation host."
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
                ? "Installed; a non-privileged sampler attempt on the validation host required superuser access; sampler output was not obtained."
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


public enum MacLeanDoctor {
    public static func benchmarkHardwareContext() -> BenchmarkHardwareContext {
        let report = buildReport()
        return BenchmarkHardwareContext(
            capturedAt: report.generatedAt,
            source: "maclean doctor allowlisted system_profiler and sysctl fields",
            modelName: report.hardware.modelName,
            modelIdentifier: report.hardware.modelIdentifier,
            processorName: report.hardware.processorName,
            processorSpeed: report.hardware.processorSpeed,
            coreCount: report.hardware.coreCount,
            memory: report.hardware.memory,
            graphicsDevices: report.hardware.graphicsDevices,
            graphicsMemory: report.hardware.graphicsMemory,
            batteryCondition: report.hardware.batteryCondition,
            batteryCycleCount: report.hardware.batteryCycleCount,
            batteryFullChargeCapacity: report.hardware.batteryFullChargeCapacity
        )
    }

    @discardableResult
    public static func run(json: Bool) -> Bool {
        let report = buildReport()
        guard json else {
            printHumanReport(report)
            return true
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(report)
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data([0x0A]))
            return true
        } catch {
            fputs("Could not encode the doctor report.\n", stderr)
            return false
        }
    }
}
