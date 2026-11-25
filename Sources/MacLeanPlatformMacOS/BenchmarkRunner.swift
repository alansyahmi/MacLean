import Foundation
import MacLeanCore

public struct BenchmarkConfiguration: Sendable {
    public let scenario: BenchmarkScenario
    public let durationSeconds: Double
    public let intervalSeconds: Double
    public let repetitions: Int
    public let warmupSeconds: Double
    public let workloadDescription: String?
    public let taskCompletionSeconds: Double?
    public let includePowermetrics: Bool

    public init(
        scenario: BenchmarkScenario,
        durationSeconds: Double,
        intervalSeconds: Double,
        repetitions: Int,
        warmupSeconds: Double,
        workloadDescription: String?,
        taskCompletionSeconds: Double?,
        includePowermetrics: Bool
    ) {
        self.scenario = scenario
        self.durationSeconds = durationSeconds
        self.intervalSeconds = intervalSeconds
        self.repetitions = repetitions
        self.warmupSeconds = warmupSeconds
        self.workloadDescription = workloadDescription
        self.taskCompletionSeconds = taskCompletionSeconds
        self.includePowermetrics = includePowermetrics
    }
}

public enum BenchmarkRunnerError: Error, CustomStringConvertible {
    case unsupportedScenario(String)
    case powermetricsAuthorization(String)

    public var description: String {
        switch self {
        case let .unsupportedScenario(reason), let .powermetricsAuthorization(reason): reason
        }
    }
}

public enum MacLeanBenchmarkRunner {
    public static func run(
        configuration: BenchmarkConfiguration,
        progress: ((Int, Double, Double) -> Void)? = nil
    ) throws -> BenchmarkResult {
        guard configuration.scenario != .cpuIntensive
                || configuration.workloadDescription?.isEmpty == false else {
            throw BenchmarkRunnerError.unsupportedScenario(
                "cpu-intensive requires --workload to identify the fixed task being timed."
            )
        }
        guard configuration.includePowermetrics == false
                || MacLeanPowermetricsCollector.authorizationError == nil else {
            throw BenchmarkRunnerError.powermetricsAuthorization(
                MacLeanPowermetricsCollector.authorizationError ?? "Privileged sampling is unavailable."
            )
        }

        let hardwareContextStart = DispatchTime.now().uptimeNanoseconds
        let hardwareContext = MacLeanDoctor.benchmarkHardwareContext()
        let hardwareContextCollectionMilliseconds = Double(
            DispatchTime.now().uptimeNanoseconds &- hardwareContextStart
        ) / 1_000_000
        var trials: [BenchmarkTrial] = []
        var host: TelemetryHostContext?
        for trialIndex in 1...configuration.repetitions {
            if configuration.warmupSeconds > 0 {
                performWarmup(
                    seconds: configuration.warmupSeconds,
                    interval: configuration.intervalSeconds
                )
            }
            let session = MacLeanTelemetrySession(includePowermetrics: configuration.includePowermetrics)
            host = host ?? session.host
            trials.append(runTrial(
                index: trialIndex,
                configuration: configuration,
                session: session,
                progress: progress
            ))
        }

        guard let host else {
            throw BenchmarkRunnerError.unsupportedScenario("No benchmark trial was run.")
        }
        return BenchmarkResult(
            createdAt: timestampString(),
            scenario: configuration.scenario,
            workloadDescription: configuration.workloadDescription,
            host: host,
            samplingIntervalSeconds: configuration.intervalSeconds,
            targetDurationSeconds: configuration.durationSeconds,
            repetitions: configuration.repetitions,
            privilegedPowermetricsEnabled: configuration.includePowermetrics,
            trials: trials,
            hardwareContext: hardwareContext,
            hardwareContextCollectionMilliseconds: hardwareContextCollectionMilliseconds,
            warmupSeconds: configuration.warmupSeconds
        )
    }

    private static func performWarmup(seconds: Double, interval: Double) {
        let session = MacLeanTelemetrySession()
        let start = DispatchTime.now().uptimeNanoseconds
        _ = session.collect(intervalSeconds: interval)
        while elapsedSeconds(since: start) < seconds {
            Thread.sleep(forTimeInterval: min(interval, seconds - elapsedSeconds(since: start)))
            _ = session.collect(intervalSeconds: interval)
        }
    }

    private static func runTrial(
        index: Int,
        configuration: BenchmarkConfiguration,
        session: MacLeanTelemetrySession,
        progress: ((Int, Double, Double) -> Void)?
    ) -> BenchmarkTrial {
        let trialStartDate = Date()
        let monotonicStart = DispatchTime.now().uptimeNanoseconds
        var lastProgress = 0.0
        var samples: [BenchmarkSample] = []

        while true {
            let telemetry = session.collect(intervalSeconds: configuration.intervalSeconds)
            let offset = elapsedSeconds(since: monotonicStart)
            samples.append(BenchmarkSample(offsetSeconds: offset, telemetry: telemetry))
            if offset - lastProgress >= 30 {
                progress?(index, offset, configuration.durationSeconds)
                lastProgress = offset
            }
            if offset >= configuration.durationSeconds { break }
            Thread.sleep(forTimeInterval: min(
                configuration.intervalSeconds,
                max(0, configuration.durationSeconds - offset)
            ))
        }

        let actualDuration = elapsedSeconds(since: monotonicStart)
        let energy = integrateDischargeEnergy(samples: samples, actualDurationSeconds: actualDuration)
        let collectorOverhead = samples.reduce(0) {
            $0 + $1.telemetry.collectorOverheadMilliseconds
        }
        let collectorCPUTime = samples.contains {
            $0.telemetry.collectorCPUTimeMilliseconds != nil
        }
            ? samples.compactMap { $0.telemetry.collectorCPUTimeMilliseconds }.reduce(0, +)
            : nil
        var metricSummaries = summarize(samples: samples)
        metricSummaries.append(scalarSummary(
            name: "battery.discharge_energy",
            unit: "Wh",
            value: energy.wattHours,
            source: "Trapezoidal integration of battery.discharge_power using monotonic offsets",
            quality: .derived,
            unavailableReason: energy.unavailableReason
        ))
        metricSummaries.append(scalarSummary(
            name: "maclean.collector_overhead",
            unit: "ms",
            value: collectorOverhead,
            source: "Sum of collector wall time; excludes waiting, JSON encoding, and output writing",
            quality: .direct
        ))
        metricSummaries.append(scalarSummary(
            name: "maclean.collector_cpu_time",
            unit: "ms",
            value: collectorCPUTime,
            source: "Sum of getrusage process and completed-child CPU time",
            quality: .direct
        ))
        if let taskCompletionSeconds = configuration.taskCompletionSeconds {
            metricSummaries.append(scalarSummary(
                name: "workload.task_completion_time",
                unit: "s",
                value: taskCompletionSeconds,
                source: "Operator-supplied task completion time",
                quality: .direct
            ))
        }
        return BenchmarkTrial(
            trialIndex: index,
            startedAt: timestampString(trialStartDate),
            endedAt: timestampString(),
            targetDurationSeconds: configuration.durationSeconds,
            actualDurationSeconds: actualDuration,
            taskCompletionSeconds: configuration.taskCompletionSeconds,
            samples: samples,
            metricSummaries: metricSummaries,
            batteryDischargeEnergy: energy,
            collectorOverheadMilliseconds: collectorOverhead,
            collectorCPUTimeMilliseconds: collectorCPUTime
        )
    }

    private static func scalarSummary(
        name: String,
        unit: String,
        value: Double?,
        source: String,
        quality: MetricQuality,
        unavailableReason: String? = nil
    ) -> BenchmarkMetricSummary {
        BenchmarkMetricSummary(
            name: name,
            unit: unit,
            sampleCount: value == nil ? 0 : 1,
            unavailableSampleCount: value == nil ? 1 : 0,
            mean: value,
            standardDeviation: nil,
            minimum: value,
            maximum: value,
            sources: [source],
            qualities: [value == nil ? .unavailable : quality],
            unavailableReason: value == nil ? unavailableReason : nil
        )
    }

    private static func summarize(samples: [BenchmarkSample]) -> [BenchmarkMetricSummary] {
        let totalSamples = samples.count
        var byName: [String: [MetricObservation]] = [:]
        for sample in samples {
            for metric in sample.telemetry.metrics {
                byName[metric.name, default: []].append(metric)
            }
        }
        return byName.keys.sorted().map { name in
            let observations = byName[name] ?? []
            let values = observations.compactMap { metric -> Double? in
                metric.quality == .unavailable ? nil : metric.value
            }
            let units = Set(observations.compactMap(\.unit))
            let consistentUnits = units.count <= 1
            let mean = values.isEmpty || !consistentUnits
                ? nil
                : values.reduce(0, +) / Double(values.count)
            let variance = mean != nil && values.count > 1
                ? values.reduce(0) { $0 + pow($1 - (mean ?? 0), 2) } / Double(values.count - 1)
                : nil
            let observedQualities = Array(Set(observations
                .filter { $0.quality != .unavailable }
                .map(\.quality)))
            return BenchmarkMetricSummary(
                name: name,
                unit: units.count == 1 ? units.first : nil,
                sampleCount: values.count,
                unavailableSampleCount: max(0, totalSamples - values.count),
                mean: mean,
                standardDeviation: variance.map(sqrt),
                minimum: consistentUnits ? values.min() : nil,
                maximum: consistentUnits ? values.max() : nil,
                sources: Array(Set(observations.map(\.source))),
                qualities: observedQualities.isEmpty ? [.unavailable] : observedQualities,
                unavailableReason: observations.compactMap(\.unavailableReason).first
                    ?? (consistentUnits ? nil : "Metric units vary within this trial.")
            )
        }
    }

    static func integrateDischargeEnergy(
        samples: [BenchmarkSample],
        actualDurationSeconds: Double
    ) -> BenchmarkEnergySummary {
        guard samples.count >= 2 else {
            return BenchmarkEnergySummary(
                wattHours: nil,
                coveredSeconds: 0,
                unavailableReason: "At least two valid power samples are needed to integrate energy."
            )
        }

        var wattSeconds = 0.0
        var coveredSeconds = 0.0
        for pair in zip(samples, samples.dropFirst()) {
            let start = pair.0
            let end = pair.1
            let interval = end.offsetSeconds - start.offsetSeconds
            guard interval > 0,
                  let startPower = metricValue("battery.discharge_power", in: start.telemetry),
                  let endPower = metricValue("battery.discharge_power", in: end.telemetry) else { continue }
            wattSeconds += (startPower + endPower) / 2 * interval
            coveredSeconds += interval
        }

        let coverageThreshold = actualDurationSeconds * 0.95
        guard coveredSeconds >= coverageThreshold else {
            return BenchmarkEnergySummary(
                wattHours: nil,
                coveredSeconds: coveredSeconds,
                unavailableReason: String(
                    format: "Valid discharge-power samples covered %.1f of %.1f seconds; total-trial energy is unavailable.",
                    coveredSeconds,
                    actualDurationSeconds
                )
            )
        }
        return BenchmarkEnergySummary(
            wattHours: wattSeconds / 3_600,
            coveredSeconds: coveredSeconds,
            unavailableReason: nil
        )
    }

    private static func metricValue(_ name: String, in record: TelemetryRecord) -> Double? {
        record.metrics.first { $0.name == name && $0.quality != .unavailable }?.value
    }

    private static func elapsedSeconds(since start: UInt64) -> Double {
        Double(DispatchTime.now().uptimeNanoseconds &- start) / 1_000_000_000
    }

    private static func timestampString(_ date: Date = Date()) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
