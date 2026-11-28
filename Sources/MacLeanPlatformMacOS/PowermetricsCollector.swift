import Darwin
import Foundation
import MacLeanCore

public enum MacLeanPowermetricsCollector {
    private static let source = "/usr/bin/powermetrics"
    private static let interruptLinePattern = try! NSRegularExpression(
        pattern: #"^\s*Vector\s+0x[0-9a-f]+\(([a-z0-9_-]{1,32})\):\s*([0-9]+(?:\.[0-9]+)?)\s+interrupts/sec\s*$"#,
        options: [.caseInsensitive]
    )
    private static let sampleWindowPattern = try! NSRegularExpression(
        pattern: #"\(([0-9]+(?:\.[0-9]+)?)ms elapsed\)"#,
        options: [.caseInsensitive]
    )

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
            unavailable("cpu.interrupt_rate", reason: reason),
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
        let sampleText = lastSampleText(in: text)
        let sampleWindowSeconds = parsedSampleWindowSeconds(in: sampleText)
        var packagePower: Double?
        var frequencyMHz: Double?
        var cStateResidency: Double?
        var interruptRatesByLabel: [String: (label: String, rate: Double)] = [:]

        for line in sampleText.split(whereSeparator: \.isNewline).map(String.init) {
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

            if let (label, rate) = interruptRate(from: line) {
                let suffix = metricSuffix(label)
                guard !suffix.isEmpty else { continue }
                let current = interruptRatesByLabel[suffix]?.rate ?? 0
                interruptRatesByLabel[suffix] = (label, current + rate)
            }
        }

        var metrics = [
            observation(
                "cpu.frequency",
                value: frequencyMHz,
                unit: "MHz",
                reason: "The installed powermetrics output did not include a recognizable Intel average-frequency field.",
                windowSeconds: sampleWindowSeconds
            ),
            observation(
                "cpu.package_power_estimate",
                value: packagePower,
                unit: "W",
                quality: .osEstimate,
                reason: "The installed powermetrics output did not include the Intel energy-model package-power field.",
                windowSeconds: sampleWindowSeconds
            ),
            observation(
                "cpu.package_c_state_residency",
                value: cStateResidency,
                unit: "%",
                reason: "The installed powermetrics output did not include Package 0 C-state residency.",
                windowSeconds: sampleWindowSeconds
            )
        ]

        if interruptRatesByLabel.isEmpty {
            metrics.append(unavailable(
                "cpu.interrupt_rate",
                reason: "The selected sampler output did not include recognizable interrupt-vector rate lines."
            ))
        } else {
            metrics.append(contentsOf: interruptRatesByLabel.keys.sorted().compactMap { suffix in
                guard let entry = interruptRatesByLabel[suffix] else { return nil }
                return MetricObservation(
                    name: "cpu.interrupt_rate.\(suffix)",
                    value: entry.rate,
                    text: entry.label,
                    unit: "interrupts/s",
                    source: "powermetrics interrupts sampler; source-label rates summed across logical CPUs",
                    quality: .derived,
                    windowSeconds: sampleWindowSeconds
                )
            })
        }

        metrics.append(
            unavailable(
                "cpu.wakeups",
                reason: "The selected sampler output's wakeup fields have not been validated for this macOS release."
            )
        )
        return metrics
    }

    private static func lastSampleText(in text: String) -> String {
        let marker = "*** Sampled system activity"
        guard let range = text.range(of: marker, options: .backwards) else { return text }
        return String(text[range.lowerBound...])
    }

    private static func parsedSampleWindowSeconds(in text: String) -> Double? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = sampleWindowPattern.firstMatch(in: text, range: range),
              let valueRange = Range(match.range(at: 1), in: text),
              let milliseconds = Double(text[valueRange]),
              milliseconds.isFinite,
              milliseconds > 0 else { return nil }
        return milliseconds / 1_000
    }

    private static func interruptRate(from line: String) -> (label: String, rate: Double)? {
        let range = NSRange(line.startIndex..., in: line)
        guard let match = interruptLinePattern.firstMatch(in: line, range: range),
              let labelRange = Range(match.range(at: 1), in: line),
              let rateRange = Range(match.range(at: 2), in: line),
              let rate = Double(line[rateRange]),
              rate.isFinite,
              rate >= 0 else { return nil }
        return (String(line[labelRange]), rate)
    }

    private static func metricSuffix(_ label: String) -> String {
        label.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
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
        reason: String,
        windowSeconds: Double? = nil
    ) -> MetricObservation {
        MetricObservation(
            name: name,
            value: value,
            unit: unit,
            source: "powermetrics cpu_power sampler (explicit privileged diagnostic)",
            quality: value == nil ? .unavailable : quality,
            windowSeconds: windowSeconds,
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
