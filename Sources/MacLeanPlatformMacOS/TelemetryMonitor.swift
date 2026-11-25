import Darwin
import Foundation
import IOKit.ps
import MacLeanCore

struct CPUTickSnapshot {
    let busy: UInt64
    let total: UInt64
}

func makeCPUTickSnapshot(user: UInt32, system: UInt32, idle: UInt32, nice: UInt32) -> CPUTickSnapshot {
    let busy = UInt64(user) + UInt64(system) + UInt64(nice)
    return CPUTickSnapshot(busy: busy, total: busy + UInt64(idle))
}

private typealias BatteryStatus = (source: String?, percent: String?, state: String?)

struct PowerSourceReading {
    let voltageMillivolts: Double?
    let currentMilliamps: Double?
    let state: String?
    let isCharging: Bool?
    let unavailableReason: String?
    let voltageSource: String
    let currentSource: String

    init(
        voltageMillivolts: Double?,
        currentMilliamps: Double?,
        state: String?,
        isCharging: Bool?,
        unavailableReason: String?,
        voltageSource: String = "IOPowerSources kIOPSVoltageKey",
        currentSource: String = "IOPowerSources kIOPSCurrentKey (signed)"
    ) {
        self.voltageMillivolts = voltageMillivolts
        self.currentMilliamps = currentMilliamps
        self.state = state
        self.isCharging = isCharging
        self.unavailableReason = unavailableReason
        self.voltageSource = voltageSource
        self.currentSource = currentSource
    }

    func fillingMissingValues(from fallback: BatteryRegistryReading?) -> PowerSourceReading {
        guard let fallback else { return self }
        let voltage = voltageMillivolts ?? fallback.voltageMillivolts
        let current = currentMilliamps ?? fallback.currentMilliamps
        return PowerSourceReading(
            voltageMillivolts: voltage,
            currentMilliamps: current,
            state: state,
            isCharging: isCharging,
            unavailableReason: voltage == nil || current == nil
                ? "IOPowerSources and the allowlisted IOPMPowerSource properties did not provide both electrical readings."
                : nil,
            voltageSource: voltageMillivolts == nil && fallback.voltageMillivolts != nil
                ? fallback.voltageSource
                : voltageSource,
            currentSource: currentMilliamps == nil && fallback.currentMilliamps != nil
                ? fallback.currentSource
                : currentSource
        )
    }

    var signedPowerWatts: Double? {
        guard let voltageMillivolts, let currentMilliamps else { return nil }
        return voltageMillivolts * currentMilliamps / 1_000_000
    }

    var dischargePowerWatts: Double? {
        guard state == "Battery Power", isCharging == false,
              let signedPowerWatts else { return nil }
        return abs(signedPowerWatts)
    }
}

public final class MacLeanTelemetrySession {
    public let host: TelemetryHostContext

    private var previousCPU: CPUTickSnapshot?
    private var previousCPUTime: UInt64
    private let initializationStart: UInt64
    private let initializationEnd: UInt64
    private let initializationCPUTime: Double?
    private var index = 0
    private let includePowermetrics: Bool

    public init(includePowermetrics: Bool = false) {
        initializationStart = DispatchTime.now().uptimeNanoseconds
        initializationCPUTime = Self.processCPUTimeMilliseconds()
        host = Self.hostContext()
        previousCPU = Self.cpuTicks()
        previousCPUTime = DispatchTime.now().uptimeNanoseconds
        initializationEnd = DispatchTime.now().uptimeNanoseconds
        self.includePowermetrics = includePowermetrics
    }

    public func collect(intervalSeconds: Double) -> TelemetryRecord {
        let start = DispatchTime.now().uptimeNanoseconds
        let cpuTimeAtStart = Self.processCPUTimeMilliseconds()
        let cpu = Self.cpuTicks()
        let cpuReadTime = DispatchTime.now().uptimeNanoseconds
        let batteryResult = CommandRunner.run(
            "/usr/bin/pmset",
            arguments: ["-g", "batt"],
            timeoutSeconds: 3
        )
        let battery = batteryResult.flatMap { result in
            result.status == 0 ? parseBatteryStatus(result.output) : nil
        }
        let powerSource = Self.powerSourceReading()
        let thermalState = thermalStateName()
        var metrics = makeMetrics(
            battery: battery,
            powerSource: powerSource,
            thermalState: thermalState,
            cpuWindowSeconds: Double(cpuReadTime &- previousCPUTime) / 1_000_000_000,
            cpuAvailable: index > 0,
            previousCPU: previousCPU,
            currentCPU: cpu
        )

        if includePowermetrics {
            metrics.append(contentsOf: MacLeanPowermetricsCollector.collect())
        } else {
            metrics.append(contentsOf: MacLeanPowermetricsCollector.unavailableMetrics(
                reason: "Disabled by default; use the explicit --powermetrics option in a benchmark."
            ))
        }

        let end = DispatchTime.now().uptimeNanoseconds
        let cpuTimeAtEnd = Self.processCPUTimeMilliseconds()
        let record = TelemetryRecord(
            timestamp: Self.timestampString(),
            host: host,
            intervalSeconds: intervalSeconds,
            collectorOverheadMilliseconds: Double(end &- start) / 1_000_000
                + (index == 0 ? Double(initializationEnd &- initializationStart) / 1_000_000 : 0),
            collectorCPUTimeMilliseconds: cpuTimeAtEnd.flatMap { current in
                (index == 0 ? initializationCPUTime : cpuTimeAtStart)
                    .map { max(0, current - $0) }
            },
            metrics: metrics
        )

        previousCPU = cpu
        previousCPUTime = cpuReadTime
        index += 1
        return record
    }

    public static func runMonitor(intervalSeconds: Double, count: Int?) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let session = MacLeanTelemetrySession()
        var index = 0
        while count.map({ index < $0 }) ?? true {
            if index > 0 { Thread.sleep(forTimeInterval: intervalSeconds) }
            let record = session.collect(intervalSeconds: intervalSeconds)
            if let data = try? encoder.encode(record) {
                FileHandle.standardOutput.write(data)
                FileHandle.standardOutput.write(Data([0x0A]))
            } else {
                fputs("Could not encode telemetry record.\n", stderr)
            }
            index += 1
        }
    }

    private func makeMetrics(
        battery: BatteryStatus?,
        powerSource: PowerSourceReading,
        thermalState: String,
        cpuWindowSeconds: Double,
        cpuAvailable: Bool,
        previousCPU: CPUTickSnapshot?,
        currentCPU: CPUTickSnapshot?
    ) -> [MetricObservation] {
        var metrics: [MetricObservation] = []
        if cpuAvailable, let previousCPU, let currentCPU,
           let utilization = Self.utilizationPercent(from: previousCPU, to: currentCPU) {
            metrics.append(MetricObservation(
                name: "cpu.utilization",
                value: utilization,
                unit: "%",
                source: "Mach host_statistics(HOST_CPU_LOAD_INFO)",
                quality: .direct,
                windowSeconds: cpuWindowSeconds
            ))
        } else {
            metrics.append(Self.unavailable(
                "cpu.utilization",
                source: "Mach host_statistics(HOST_CPU_LOAD_INFO)",
                reason: "The first sample establishes a baseline or the host counter read failed."
            ))
        }

        if let percentText = battery?.percent?.replacingOccurrences(of: "%", with: ""),
           let percent = Double(percentText) {
            metrics.append(MetricObservation(
                name: "battery.state_of_charge",
                value: percent,
                unit: "%",
                source: "/usr/bin/pmset -g batt",
                quality: .osEstimate
            ))
        } else {
            metrics.append(Self.unavailable(
                "battery.state_of_charge",
                source: "/usr/bin/pmset -g batt",
                reason: "The command failed or did not expose a battery percentage."
            ))
        }

        metrics.append(MetricObservation(
            name: "battery.power_source",
            text: battery?.source,
            source: "/usr/bin/pmset -g batt",
            quality: battery?.source == nil ? .unavailable : .direct,
            unavailableReason: battery?.source == nil
                ? "The command failed or did not expose a power source."
                : nil
        ))
        metrics.append(MetricObservation(
            name: "battery.charging_state",
            text: battery?.state,
            source: "/usr/bin/pmset -g batt",
            quality: battery?.state == nil ? .unavailable : .direct,
            unavailableReason: battery?.state == nil
                ? "The command failed or did not expose a charging state."
                : nil
        ))
        metrics.append(MetricObservation(
            name: "battery.voltage",
            value: powerSource.voltageMillivolts.map { $0 / 1_000 },
            unit: "V",
            source: powerSource.voltageSource,
            quality: powerSource.voltageMillivolts == nil ? .unavailable : .direct,
            unavailableReason: powerSource.voltageMillivolts == nil
                ? (powerSource.unavailableReason ?? "Neither IOPowerSources nor the IOPMPowerSource fallback published voltage.")
                : nil
        ))
        metrics.append(MetricObservation(
            name: "battery.current",
            value: powerSource.currentMilliamps.map { $0 / 1_000 },
            unit: "A",
            source: powerSource.currentSource,
            quality: powerSource.currentMilliamps == nil ? .unavailable : .direct,
            unavailableReason: powerSource.currentMilliamps == nil
                ? (powerSource.unavailableReason ?? "Neither IOPowerSources nor the IOPMPowerSource fallback published current.")
                : nil
        ))
        metrics.append(MetricObservation(
            name: "battery.signed_power",
            value: powerSource.signedPowerWatts,
            unit: "W",
            source: "\(powerSource.voltageSource) × \(powerSource.currentSource)",
            quality: powerSource.signedPowerWatts == nil ? .unavailable : .derived,
            unavailableReason: powerSource.signedPowerWatts == nil
                ? "Both voltage and signed current are required; no substitute is used."
                : nil
        ))
        metrics.append(MetricObservation(
            name: "battery.discharge_power",
            value: powerSource.dischargePowerWatts,
            unit: "W",
            source: "\(powerSource.voltageSource) × \(powerSource.currentSource); IOPowerSources Battery Power and not charging",
            quality: powerSource.dischargePowerWatts == nil ? .unavailable : .derived,
            unavailableReason: powerSource.dischargePowerWatts == nil
                ? "A battery-powered, non-charging state and both electrical readings are required."
                : nil
        ))
        metrics.append(MetricObservation(
            name: "battery.iokit_power_state",
            text: powerSource.state,
            source: "IOPowerSources kIOPSPowerSourceStateKey",
            quality: powerSource.state == nil ? .unavailable : .direct,
            unavailableReason: powerSource.state == nil ? powerSource.unavailableReason : nil
        ))
        metrics.append(MetricObservation(
            name: "battery.iokit_charging",
            text: powerSource.isCharging.map { $0 ? "true" : "false" },
            source: "IOPowerSources kIOPSIsChargingKey",
            quality: powerSource.isCharging == nil ? .unavailable : .direct,
            unavailableReason: powerSource.isCharging == nil ? powerSource.unavailableReason : nil
        ))
        metrics.append(MetricObservation(
            name: "thermal.system_state",
            text: thermalState,
            source: "Foundation ProcessInfo.thermalState",
            quality: .direct
        ))

        metrics.append(contentsOf: MacLeanGPUActivityCollector.collect())
        metrics.append(contentsOf: [
            Self.unavailable(
                "thunderbolt.controller_power",
                source: "No validated source",
                reason: "No validated read-only controller power-state source is available."
            ),
            Self.unavailable(
                "thermal.temperature",
                source: "No validated source",
                reason: "ProcessInfo exposes only a coarse thermal state, not a physical temperature."
            ),
            Self.unavailable(
                "thermal.fan_speed",
                source: "No validated source",
                reason: "No validated read-only fan-speed source is available."
            )
        ])
        return metrics
    }

    private static func unavailable(
        _ name: String,
        source: String,
        reason: String
    ) -> MetricObservation {
        MetricObservation(
            name: name,
            source: source,
            quality: .unavailable,
            unavailableReason: reason
        )
    }

    private static func powerSourceReading() -> PowerSourceReading {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sourceList = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            return PowerSourceReading(
                voltageMillivolts: nil,
                currentMilliamps: nil,
                state: nil,
                isCharging: nil,
                unavailableReason: "IOPowerSources could not provide a power-source snapshot."
            ).fillingMissingValues(from: MacLeanBatteryRegistryCollector.readMissing(voltage: true, current: true))
        }

        for source in sourceList {
            guard let description = IOPSGetPowerSourceDescription(blob, source),
                  let values = description.takeUnretainedValue() as? [String: Any],
                  values["Type"] as? String == "InternalBattery",
                  (values["Is Present"] as? NSNumber)?.boolValue != false else { continue }
            let reading = PowerSourceReading(
                voltageMillivolts: (values["Voltage"] as? NSNumber)?.doubleValue,
                currentMilliamps: (values["Current"] as? NSNumber)?.doubleValue,
                state: values["Power Source State"] as? String,
                isCharging: (values["Is Charging"] as? NSNumber)?.boolValue,
                unavailableReason: nil
            )
            return reading.fillingMissingValues(from: MacLeanBatteryRegistryCollector.readMissing(
                voltage: reading.voltageMillivolts == nil,
                current: reading.currentMilliamps == nil
            ))
        }
        return PowerSourceReading(
            voltageMillivolts: nil,
            currentMilliamps: nil,
            state: nil,
            isCharging: nil,
            unavailableReason: "No present internal battery was exposed by IOPowerSources."
        ).fillingMissingValues(from: MacLeanBatteryRegistryCollector.readMissing(voltage: true, current: true))
    }

    private static func cpuTicks() -> CPUTickSnapshot? {
        var info = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
        )
        let status = withUnsafeMutablePointer(to: &info) { infoPointer in
            infoPointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { return nil }

        let ticks = info.cpu_ticks
        return makeCPUTickSnapshot(user: ticks.0, system: ticks.1, idle: ticks.2, nice: ticks.3)
    }

    static func utilizationPercent(
        from previous: CPUTickSnapshot,
        to current: CPUTickSnapshot
    ) -> Double? {
        guard current.total > previous.total else { return nil }
        let totalDelta = current.total - previous.total
        let busyDelta = current.busy >= previous.busy ? current.busy - previous.busy : 0
        return min(100, Double(busyDelta) / Double(totalDelta) * 100)
    }

    private static func processCPUTimeMilliseconds() -> Double? {
        var ownUsage = rusage()
        var childUsage = rusage()
        guard getrusage(RUSAGE_SELF, &ownUsage) == 0,
              getrusage(RUSAGE_CHILDREN, &childUsage) == 0 else { return nil }

        func milliseconds(_ usage: rusage) -> Double {
            let user = Double(usage.ru_utime.tv_sec) * 1_000
                + Double(usage.ru_utime.tv_usec) / 1_000
            let system = Double(usage.ru_stime.tv_sec) * 1_000
                + Double(usage.ru_stime.tv_usec) / 1_000
            return user + system
        }
        return milliseconds(ownUsage) + milliseconds(childUsage)
    }

    private static func hostContext() -> TelemetryHostContext {
        TelemetryHostContext(
            operatingSystemVersion: CommandRunner.value(
                "/usr/bin/sw_vers",
                arguments: ["-productVersion"],
                timeoutSeconds: 2
            ) ?? ProcessInfo.processInfo.operatingSystemVersionString,
            operatingSystemBuild: CommandRunner.value(
                "/usr/bin/sw_vers",
                arguments: ["-buildVersion"],
                timeoutSeconds: 2
            ),
            architecture: CommandRunner.value(
                "/usr/bin/uname",
                arguments: ["-m"],
                timeoutSeconds: 2
            ) ?? "unknown",
            modelIdentifier: CommandRunner.value(
                "/usr/sbin/sysctl",
                arguments: ["-n", "hw.model"],
                timeoutSeconds: 2
            ),
            processorName: CommandRunner.value(
                "/usr/sbin/sysctl",
                arguments: ["-n", "machdep.cpu.brand_string"],
                timeoutSeconds: 2
            ),
            physicalCPUCount: CommandRunner.value(
                "/usr/sbin/sysctl",
                arguments: ["-n", "hw.physicalcpu"],
                timeoutSeconds: 2
            ).flatMap(Int.init),
            logicalCPUCount: CommandRunner.value(
                "/usr/sbin/sysctl",
                arguments: ["-n", "hw.logicalcpu"],
                timeoutSeconds: 2
            ).flatMap(Int.init),
            memoryBytes: CommandRunner.value(
                "/usr/sbin/sysctl",
                arguments: ["-n", "hw.memsize"],
                timeoutSeconds: 2
            ).flatMap(UInt64.init)
        )
    }

    private static func timestampString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
}

public enum MacLeanMonitor {
    public static func run(intervalSeconds: Double, count: Int?) {
        MacLeanTelemetrySession.runMonitor(intervalSeconds: intervalSeconds, count: count)
    }
}
