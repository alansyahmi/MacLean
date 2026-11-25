import Darwin
import Foundation
import MacLeanCore

private struct CPUTickSnapshot {
    let busy: UInt64
    let total: UInt64
}

public enum MacLeanMonitor {
    public static func run(intervalSeconds: Double, count: Int?) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let initializationStart = DispatchTime.now().uptimeNanoseconds
        let initializationCPUStart = processCPUTimeMilliseconds()
        let host = hostContext()
        var previousCPU = cpuTicks()
        var previousCPUTime = DispatchTime.now().uptimeNanoseconds
        let initializationEnd = DispatchTime.now().uptimeNanoseconds
        var index = 0

        while count.map({ index < $0 }) ?? true {
            if index > 0 {
                Thread.sleep(forTimeInterval: intervalSeconds)
            }

            let start = DispatchTime.now().uptimeNanoseconds
            let cpuTimeAtStart = processCPUTimeMilliseconds()
            let cpu = cpuTicks()
            let cpuReadTime = DispatchTime.now().uptimeNanoseconds
            let batteryResult = CommandRunner.run(
                "/usr/bin/pmset",
                arguments: ["-g", "batt"],
                timeoutSeconds: 3
            )
            let battery = batteryResult.flatMap { result in
                result.status == 0 ? parseBatteryStatus(result.output) : nil
            }
            let thermalState = thermalStateName()
            let end = DispatchTime.now().uptimeNanoseconds
            let cpuTimeAtEnd = processCPUTimeMilliseconds()

            let windowSeconds = Double(cpuReadTime &- previousCPUTime) / 1_000_000_000
            var metrics: [MetricObservation] = []
            if index > 0, let previousCPU, let cpu,
               let utilization = utilizationPercent(from: previousCPU, to: cpu) {
                metrics.append(MetricObservation(
                    name: "cpu.utilization",
                    value: utilization,
                    unit: "%",
                    source: "Mach host_statistics(HOST_CPU_LOAD_INFO)",
                    quality: .direct,
                    windowSeconds: windowSeconds
                ))
            } else {
                metrics.append(unavailable(
                    "cpu.utilization",
                    source: "Mach host_statistics(HOST_CPU_LOAD_INFO)",
                    reason: "The first sample establishes a baseline; utilization appears after the first configured interval."
                ))
            }

            if let battery,
               let percentText = battery.percent?.replacingOccurrences(of: "%", with: ""),
               let percent = Double(percentText) {
                metrics.append(MetricObservation(
                    name: "battery.state_of_charge",
                    value: percent,
                    unit: "%",
                    source: "/usr/bin/pmset -g batt",
                    quality: .osEstimate
                ))
            } else {
                metrics.append(unavailable(
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
                name: "thermal.system_state",
                text: thermalState,
                source: "Foundation ProcessInfo.thermalState",
                quality: .direct
            ))

            metrics.append(contentsOf: [
                unavailable(
                    "cpu.frequency",
                    source: "powermetrics cpu_power sampler",
                    reason: "The access requirement varies by host; this monitor does not invoke powermetrics or request privileges automatically."
                ),
                unavailable(
                    "cpu.package_c_state_residency",
                    source: "powermetrics cpu_power sampler",
                    reason: "The access requirement varies by host; this monitor does not invoke powermetrics or request privileges automatically."
                ),
                unavailable(
                    "cpu.interrupts_and_wakeups",
                    source: "powermetrics interrupts sampler",
                    reason: "The access requirement varies by host; this monitor does not invoke powermetrics or request privileges automatically."
                ),
                unavailable(
                    "battery.voltage",
                    source: "powermetrics battery sampler",
                    reason: "No validated non-privileged per-sample voltage source is available."
                ),
                unavailable(
                    "battery.current",
                    source: "powermetrics battery sampler",
                    reason: "No validated non-privileged per-sample current source is available."
                ),
                unavailable(
                    "battery.discharge_rate",
                    source: "Derived from battery energy over time",
                    reason: "The available battery percentage is coarse and does not support a reliable short-window discharge estimate."
                ),
                unavailable(
                    "graphics.active_device",
                    source: "Live GPU activity source",
                    reason: "Hardware inventory identifies GPU models but not which GPU is active."
                ),
                unavailable(
                    "graphics.power",
                    source: "powermetrics GPU sampler",
                    reason: "No validated non-privileged per-sample GPU power source is available."
                ),
                unavailable(
                    "thunderbolt.topology",
                    source: "system_profiler inventory",
                    reason: "Controller and device inventory is not sampled at monitor cadence."
                ),
                unavailable(
                    "thunderbolt.controller_power",
                    source: "No validated source",
                    reason: "No validated read-only controller power-state source is available."
                ),
                unavailable(
                    "thermal.temperature",
                    source: "No validated source",
                    reason: "ProcessInfo exposes only a coarse thermal state, not a physical temperature."
                ),
                unavailable(
                    "thermal.fan_speed",
                    source: "No validated source",
                    reason: "No validated read-only fan-speed source is available."
                )
            ])

            let record = TelemetryRecord(
                timestamp: timestampString(),
                host: host,
                intervalSeconds: intervalSeconds,
                collectorOverheadMilliseconds: Double(end &- start) / 1_000_000
                    + (index == 0 ? Double(initializationEnd &- initializationStart) / 1_000_000 : 0),
                collectorCPUTimeMilliseconds: cpuTimeAtEnd.flatMap { current in
                    (index == 0 ? initializationCPUStart : cpuTimeAtStart)
                        .map { max(0, current - $0) }
                },
                metrics: metrics
            )
            if let data = try? encoder.encode(record) {
                FileHandle.standardOutput.write(data)
                FileHandle.standardOutput.write(Data([0x0A]))
            } else {
                fputs("Could not encode telemetry record.\n", stderr)
            }

            previousCPU = cpu
            previousCPUTime = cpuReadTime
            index += 1
        }
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
        let user = UInt64(ticks.0)
        let system = UInt64(ticks.1)
        let nice = UInt64(ticks.2)
        let idle = UInt64(ticks.3)
        return CPUTickSnapshot(busy: user + system + nice, total: user + system + nice + idle)
    }

    private static func utilizationPercent(
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
            )
        )
    }

    private static func timestampString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
}
