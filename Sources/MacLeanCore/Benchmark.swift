import Foundation

public enum BenchmarkScenario: String, Codable, CaseIterable, Sendable {
    case desktopIdle = "desktop-idle"
    case screenOffIdle = "screen-off-idle"
    case lightProductivity = "light-productivity"
    case videoPlayback = "video-playback"
    case cpuIntensive = "cpu-intensive"

    public var suggestedDurationSeconds: Double? {
        switch self {
        case .desktopIdle, .screenOffIdle: 600
        case .lightProductivity, .videoPlayback: 900
        case .cpuIntensive: nil
        }
    }
}

public struct BenchmarkSample: Codable, Sendable {
    public let offsetSeconds: Double
    public let telemetry: TelemetryRecord

    public init(offsetSeconds: Double, telemetry: TelemetryRecord) {
        self.offsetSeconds = offsetSeconds
        self.telemetry = telemetry
    }
}

public struct BenchmarkMetricSummary: Codable, Sendable {
    public let name: String
    public let unit: String?
    public let sampleCount: Int
    public let unavailableSampleCount: Int
    public let mean: Double?
    public let standardDeviation: Double?
    public let minimum: Double?
    public let maximum: Double?
    public let sources: [String]
    public let qualities: [MetricQuality]
    public let unavailableReason: String?

    public init(
        name: String,
        unit: String?,
        sampleCount: Int,
        unavailableSampleCount: Int,
        mean: Double?,
        standardDeviation: Double?,
        minimum: Double?,
        maximum: Double?,
        sources: [String],
        qualities: [MetricQuality],
        unavailableReason: String? = nil
    ) {
        self.name = name
        self.unit = unit
        self.sampleCount = sampleCount
        self.unavailableSampleCount = unavailableSampleCount
        self.mean = mean
        self.standardDeviation = standardDeviation
        self.minimum = minimum
        self.maximum = maximum
        self.sources = sources.sorted()
        self.qualities = qualities.sorted { $0.rawValue < $1.rawValue }
        self.unavailableReason = unavailableReason
    }
}

public struct BenchmarkEnergySummary: Codable, Sendable {
    public let wattHours: Double?
    public let coveredSeconds: Double
    public let unavailableReason: String?

    public init(wattHours: Double?, coveredSeconds: Double, unavailableReason: String?) {
        self.wattHours = wattHours
        self.coveredSeconds = coveredSeconds
        self.unavailableReason = unavailableReason
    }
}

public struct BenchmarkHardwareContext: Codable, Sendable {
    public let capturedAt: String
    public let source: String
    public let modelName: String?
    public let modelIdentifier: String?
    public let processorName: String?
    public let processorSpeed: String?
    public let coreCount: String?
    public let memory: String?
    public let graphicsDevices: [String]
    public let graphicsMemory: String?
    public let batteryCondition: String?
    public let batteryCycleCount: String?
    public let batteryFullChargeCapacity: String?

    public init(
        capturedAt: String,
        source: String,
        modelName: String?,
        modelIdentifier: String?,
        processorName: String?,
        processorSpeed: String?,
        coreCount: String?,
        memory: String?,
        graphicsDevices: [String],
        graphicsMemory: String?,
        batteryCondition: String?,
        batteryCycleCount: String?,
        batteryFullChargeCapacity: String?
    ) {
        self.capturedAt = capturedAt
        self.source = source
        self.modelName = modelName
        self.modelIdentifier = modelIdentifier
        self.processorName = processorName
        self.processorSpeed = processorSpeed
        self.coreCount = coreCount
        self.memory = memory
        self.graphicsDevices = graphicsDevices
        self.graphicsMemory = graphicsMemory
        self.batteryCondition = batteryCondition
        self.batteryCycleCount = batteryCycleCount
        self.batteryFullChargeCapacity = batteryFullChargeCapacity
    }
}

public struct BenchmarkTrial: Codable, Sendable {
    public let trialIndex: Int
    public let startedAt: String
    public let endedAt: String
    public let targetDurationSeconds: Double
    public let actualDurationSeconds: Double
    public let taskCompletionSeconds: Double?
    public let samples: [BenchmarkSample]
    public let metricSummaries: [BenchmarkMetricSummary]
    public let batteryDischargeEnergy: BenchmarkEnergySummary
    public let collectorOverheadMilliseconds: Double
    public let collectorCPUTimeMilliseconds: Double?

    public init(
        trialIndex: Int,
        startedAt: String,
        endedAt: String,
        targetDurationSeconds: Double,
        actualDurationSeconds: Double,
        taskCompletionSeconds: Double?,
        samples: [BenchmarkSample],
        metricSummaries: [BenchmarkMetricSummary],
        batteryDischargeEnergy: BenchmarkEnergySummary,
        collectorOverheadMilliseconds: Double,
        collectorCPUTimeMilliseconds: Double?
    ) {
        self.trialIndex = trialIndex
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.targetDurationSeconds = targetDurationSeconds
        self.actualDurationSeconds = actualDurationSeconds
        self.taskCompletionSeconds = taskCompletionSeconds
        self.samples = samples
        self.metricSummaries = metricSummaries
        self.batteryDischargeEnergy = batteryDischargeEnergy
        self.collectorOverheadMilliseconds = collectorOverheadMilliseconds
        self.collectorCPUTimeMilliseconds = collectorCPUTimeMilliseconds
    }
}

public struct BenchmarkResult: Codable, Sendable {
    public let schemaVersion: Int
    public let runID: String
    public let createdAt: String
    public let scenario: BenchmarkScenario
    public let workloadDescription: String?
    public let host: TelemetryHostContext
    public let hardwareContext: BenchmarkHardwareContext?
    public let hardwareContextCollectionMilliseconds: Double?
    public let samplingIntervalSeconds: Double
    public let targetDurationSeconds: Double
    public let repetitions: Int
    public let warmupSeconds: Double?
    public let privilegedPowermetricsEnabled: Bool
    public let trials: [BenchmarkTrial]

    public init(
        schemaVersion: Int = 1,
        runID: String = UUID().uuidString,
        createdAt: String,
        scenario: BenchmarkScenario,
        workloadDescription: String?,
        host: TelemetryHostContext,
        samplingIntervalSeconds: Double,
        targetDurationSeconds: Double,
        repetitions: Int,
        privilegedPowermetricsEnabled: Bool,
        trials: [BenchmarkTrial],
        hardwareContext: BenchmarkHardwareContext? = nil,
        hardwareContextCollectionMilliseconds: Double? = nil,
        warmupSeconds: Double? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.runID = runID
        self.createdAt = createdAt
        self.scenario = scenario
        self.workloadDescription = workloadDescription
        self.host = host
        self.hardwareContext = hardwareContext
        self.hardwareContextCollectionMilliseconds = hardwareContextCollectionMilliseconds
        self.samplingIntervalSeconds = samplingIntervalSeconds
        self.targetDurationSeconds = targetDurationSeconds
        self.repetitions = repetitions
        self.warmupSeconds = warmupSeconds
        self.privilegedPowermetricsEnabled = privilegedPowermetricsEnabled
        self.trials = trials
    }
}

public struct BenchmarkMetricComparison: Codable, Sendable {
    public let name: String
    public let unit: String?
    public let baselineMean: Double?
    public let candidateMean: Double?
    public let absoluteChange: Double?
    public let percentChange: Double?
    public let unavailableReason: String?

    public init(
        name: String,
        unit: String?,
        baselineMean: Double?,
        candidateMean: Double?,
        absoluteChange: Double?,
        percentChange: Double?,
        unavailableReason: String?
    ) {
        self.name = name
        self.unit = unit
        self.baselineMean = baselineMean
        self.candidateMean = candidateMean
        self.absoluteChange = absoluteChange
        self.percentChange = percentChange
        self.unavailableReason = unavailableReason
    }
}

public struct BenchmarkComparison: Codable, Sendable {
    public let scenario: BenchmarkScenario
    public let baselineRunID: String
    public let candidateRunID: String
    public let metrics: [BenchmarkMetricComparison]

    private struct ComparableMean {
        let value: Double?
        let unit: String?
        let sources: [String]
        let qualities: [MetricQuality]
        let unavailableReason: String?
    }

    public init(baseline: BenchmarkResult, candidate: BenchmarkResult) {
        scenario = baseline.scenario
        baselineRunID = baseline.runID
        candidateRunID = candidate.runID

        let baselineMeans = Self.meanSummaries(in: baseline)
        let candidateMeans = Self.meanSummaries(in: candidate)
        metrics = Set(baselineMeans.keys).union(candidateMeans.keys).sorted().map { name in
            guard baseline.scenario == candidate.scenario else {
                return BenchmarkMetricComparison(
                    name: name,
                    unit: nil,
                    baselineMean: nil,
                    candidateMean: nil,
                    absoluteChange: nil,
                    percentChange: nil,
                    unavailableReason: "Scenario names differ."
                )
            }
            guard let baselineSummary = baselineMeans[name], let candidateSummary = candidateMeans[name] else {
                return BenchmarkMetricComparison(
                    name: name,
                    unit: baselineMeans[name]?.unit ?? candidateMeans[name]?.unit,
                    baselineMean: baselineMeans[name]?.value,
                    candidateMean: candidateMeans[name]?.value,
                    absoluteChange: nil,
                    percentChange: nil,
                    unavailableReason: baselineMeans[name]?.unavailableReason
                        ?? candidateMeans[name]?.unavailableReason
                        ?? "A compatible numeric mean is unavailable."
                )
            }
            guard baselineSummary.unit == candidateSummary.unit else {
                return BenchmarkMetricComparison(
                    name: name,
                    unit: nil,
                    baselineMean: baselineSummary.value,
                    candidateMean: candidateSummary.value,
                    absoluteChange: nil,
                    percentChange: nil,
                    unavailableReason: "Metric units differ between runs."
                )
            }
            guard let baselineValue = baselineSummary.value, let candidateValue = candidateSummary.value else {
                return BenchmarkMetricComparison(
                    name: name,
                    unit: baselineSummary.unit,
                    baselineMean: baselineSummary.value,
                    candidateMean: candidateSummary.value,
                    absoluteChange: nil,
                    percentChange: nil,
                    unavailableReason: baselineSummary.unavailableReason
                        ?? candidateSummary.unavailableReason
                        ?? "A compatible numeric mean is unavailable."
                )
            }
            guard baselineSummary.sources == candidateSummary.sources,
                  baselineSummary.qualities == candidateSummary.qualities else {
                return BenchmarkMetricComparison(
                    name: name,
                    unit: baselineSummary.unit,
                    baselineMean: baselineValue,
                    candidateMean: candidateValue,
                    absoluteChange: nil,
                    percentChange: nil,
                    unavailableReason: "Measurement sources or quality differ between runs."
                )
            }
            let difference = candidateValue - baselineValue
            return BenchmarkMetricComparison(
                name: name,
                unit: baselineSummary.unit,
                baselineMean: baselineValue,
                candidateMean: candidateValue,
                absoluteChange: difference,
                percentChange: baselineValue == 0
                    ? nil
                    : difference / abs(baselineValue) * 100,
                unavailableReason: baselineValue == 0
                    ? "Percent change is undefined because the baseline mean is zero."
                    : nil
            )
        }
    }

    private static func meanSummaries(in result: BenchmarkResult) -> [String: ComparableMean] {
        var grouped: [String: [BenchmarkMetricSummary]] = [:]
        for summary in result.trials.flatMap(\.metricSummaries) {
            grouped[summary.name, default: []].append(summary)
        }
        return grouped.mapValues { summaries in
            let units = Set(summaries.map(\.unit))
            let means = summaries.compactMap(\.mean)
            let hasConsistentUnits = units.count == 1
            let sources = Set(summaries.flatMap(\.sources)).sorted()
            let qualities = Set(summaries.flatMap(\.qualities)).sorted { $0.rawValue < $1.rawValue }
            return ComparableMean(
                value: means.isEmpty || !hasConsistentUnits
                    ? nil
                    : means.reduce(0, +) / Double(means.count),
                unit: hasConsistentUnits ? units.first ?? nil : nil,
                sources: sources,
                qualities: qualities,
                unavailableReason: summaries.compactMap(\.unavailableReason).first
                    ?? (hasConsistentUnits ? nil : "Metric units differ between trials.")
            )
        }
    }

}

public enum BenchmarkCompatibility {
    public static func incompatibilityReason(
        baseline: BenchmarkResult,
        candidate: BenchmarkResult
    ) -> String? {
        guard baseline.scenario == candidate.scenario else {
            return "Runs use different scenarios."
        }
        guard baseline.targetDurationSeconds == candidate.targetDurationSeconds,
              baseline.samplingIntervalSeconds == candidate.samplingIntervalSeconds,
              baseline.repetitions == candidate.repetitions,
              baseline.warmupSeconds == candidate.warmupSeconds,
              baseline.workloadDescription == candidate.workloadDescription,
              baseline.privilegedPowermetricsEnabled == candidate.privilegedPowermetricsEnabled else {
            return "Runs use different duration, interval, repetition, warm-up, workload, or diagnostic settings."
        }
        guard baseline.host.architecture == candidate.host.architecture else {
            return "Runs use different architectures."
        }
        guard let baselineBuild = baseline.host.operatingSystemBuild,
              let candidateBuild = candidate.host.operatingSystemBuild,
              baselineBuild == candidateBuild else {
            return "Runs do not have the same known macOS build."
        }

        let left = baseline.hardwareContext
        let right = candidate.hardwareContext
        let leftModelIdentifier = left?.modelIdentifier ?? baseline.host.modelIdentifier
        let rightModelIdentifier = right?.modelIdentifier ?? candidate.host.modelIdentifier
        let sameModelIdentifier = matchingKnown(leftModelIdentifier, rightModelIdentifier)
        let sameModelName = matchingKnown(left?.modelName, right?.modelName)
        if let leftID = leftModelIdentifier, let rightID = rightModelIdentifier, leftID != rightID {
            return "Runs identify different model identifiers."
        }
        if let leftName = left?.modelName, let rightName = right?.modelName, leftName != rightName {
            return "Runs identify different model names."
        }
        if let leftCPU = left?.processorName ?? baseline.host.processorName,
           let rightCPU = right?.processorName ?? candidate.host.processorName,
           leftCPU != rightCPU {
            return "Runs identify different processor names."
        }

        if let left, let right {
            if mismatches(left.coreCount, right.coreCount)
                || mismatches(left.memory, right.memory)
                || mismatches(left.graphicsDevices.isEmpty ? nil : left.graphicsDevices,
                              right.graphicsDevices.isEmpty ? nil : right.graphicsDevices) {
                return "Runs have conflicting core, memory, or graphics inventory."
            }
        }

        let sameProcessorName = matchingKnown(
            left?.processorName ?? baseline.host.processorName,
            right?.processorName ?? candidate.host.processorName
        )
        let sameCoreMemoryGraphics = left?.coreCount != nil
            && right?.coreCount != nil
            && left?.memory != nil
            && right?.memory != nil
            && left?.graphicsDevices.isEmpty == false
            && right?.graphicsDevices.isEmpty == false
            && left?.coreCount == right?.coreCount
            && left?.memory == right?.memory
            && left?.graphicsDevices == right?.graphicsDevices
        guard sameModelIdentifier || sameModelName || sameProcessorName || sameCoreMemoryGraphics else {
            return "The available hardware context is insufficient to establish comparable machines."
        }
        return nil
    }

    private static func matchingKnown<Value: Equatable>(_ left: Value?, _ right: Value?) -> Bool {
        guard let left, let right else { return false }
        return left == right
    }

    private static func mismatches<Value: Equatable>(_ left: Value?, _ right: Value?) -> Bool {
        guard let left, let right else { return false }
        return left != right
    }
}
