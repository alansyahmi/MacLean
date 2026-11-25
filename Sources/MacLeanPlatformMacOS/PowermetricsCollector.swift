import Darwin
import Foundation
import MacLeanCore

public enum MacLeanPowermetricsCollector {
    private static let source = "/usr/bin/powermetrics"

    public static var authorizationError: String? {
        guard FileManager.default.isExecutableFile(atPath: source) else {
            return "The macOS powermetrics utility is unavailable."
        }
        guard geteuid() == 0 else {
            return "powermetrics requires an explicitly privileged process on this host. Re-run the benchmark yourself with administrator authorization; MacLean never invokes sudo or elevates automatically."
        }
        return nil
    }

    public static func unavailableMetrics(reason: String) -> [MetricObservation] {
        [
            unavailable("cpu.frequency", reason: reason),
            unavailable("cpu.package_power_estimate", reason: reason),
            unavailable("cpu.package_c_state_residency", reason: reason),
            unavailable("cpu.wakeups", reason: reason)
        ]
    }

    public static func collect() -> [MetricObservation] {
        guard authorizationError == nil else {
            return unavailableMetrics(reason: authorizationError ?? "Privileged sampler is unavailable.")
        }
        guard let result = CommandRunner.run(
            source,
            arguments: ["-n", "1", "-i", "1000", "-s", "cpu_power,battery,interrupts", "-f", "text"],
            timeoutSeconds: 15
        ), result.status == 0 else {
            return unavailableMetrics(
                reason: "powermetrics did not complete successfully; no automatic retry or elevation was attempted."
            )
        }
        return parseIntelCPUText(result.output)
    }

    static func parseIntelCPUText(_ text: String) -> [MetricObservation] {
        var packagePower: Double?
        var frequencyMHz: Double?
        var cStateResidency: Double?

        for line in text.split(whereSeparator: \.isNewline).map(String.init) {
            let lower = line.lowercased()
            if lower.contains("intel energy model derived package power"),
               let value = number(beforeUnit: "w", in: valueAfterColon(line)) {
                packagePower = value
            } else if lower.contains("system average frequency"),
                      let opening = line.firstIndex(of: "("),
                      let closing = line[opening...].firstIndex(of: ")") {
                let frequencyText = String(line[line.index(after: opening)..<closing])
                frequencyMHz = number(beforeUnit: "mhz", in: frequencyText)
            } else if lower.contains("package 0 c-state residency"),
                      let value = number(beforeUnit: "%", in: valueAfterColon(line)) {
                cStateResidency = value
            }
        }

        return [
            observation(
                "cpu.frequency",
                value: frequencyMHz,
                unit: "MHz",
                reason: "The installed powermetrics output did not include a recognizable Intel average-frequency field."
            ),
            observation(
                "cpu.package_power_estimate",
                value: packagePower,
                unit: "W",
                quality: .osEstimate,
                reason: "The installed powermetrics output did not include the Intel energy-model package-power field."
            ),
            observation(
                "cpu.package_c_state_residency",
                value: cStateResidency,
                unit: "%",
                reason: "The installed powermetrics output did not include Package 0 C-state residency."
            ),
            unavailable(
                "cpu.wakeups",
                reason: "The selected sampler output's wakeup fields have not been validated for this macOS release."
            )
        ]
    }

    private static func valueAfterColon(_ line: String) -> String {
        guard let colon = line.firstIndex(of: ":") else { return "" }
        return String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
    }

    private static func number(beforeUnit unit: String, in text: String) -> Double? {
        guard let range = text.lowercased().range(of: unit) else { return nil }
        let prefix = text[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
        let token = prefix.split(whereSeparator: { !$0.isNumber && $0 != "." && $0 != "-" }).last
        return token.flatMap { Double($0) }
    }

    private static func observation(
        _ name: String,
        value: Double?,
        unit: String,
        quality: MetricQuality = .direct,
        reason: String
    ) -> MetricObservation {
        MetricObservation(
            name: name,
            value: value,
            unit: unit,
            source: "powermetrics cpu_power sampler (explicit privileged diagnostic)",
            quality: value == nil ? .unavailable : quality,
            unavailableReason: value == nil ? reason : nil
        )
    }

    private static func unavailable(_ name: String, reason: String) -> MetricObservation {
        MetricObservation(
            name: name,
            source: "powermetrics cpu_power, battery, interrupts samplers",
            quality: .unavailable,
            unavailableReason: reason
        )
    }
}
