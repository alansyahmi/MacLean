import Foundation

public enum MetricQuality: String, Codable, Sendable {
    case direct
    case derived
    case osEstimate
    case unavailable
}

public struct MetricObservation: Codable, Sendable {
    public let name: String
    public let value: Double?
    public let text: String?
    public let unit: String?
    public let source: String
    public let quality: MetricQuality
    public let windowSeconds: Double?
    public let unavailableReason: String?

    public init(
        name: String,
        value: Double? = nil,
        text: String? = nil,
        unit: String? = nil,
        source: String,
        quality: MetricQuality,
        windowSeconds: Double? = nil,
        unavailableReason: String? = nil
    ) {
        self.name = name
        self.value = value
        self.text = text
        self.unit = unit
        self.source = source
        self.quality = quality
        self.windowSeconds = windowSeconds
        self.unavailableReason = unavailableReason
    }
}

public struct TelemetryRecord: Codable, Sendable {
    public let timestamp: String
    public let host: TelemetryHostContext
    public let intervalSeconds: Double
    public let collectorOverheadMilliseconds: Double
    public let collectorCPUTimeMilliseconds: Double?
    public let metrics: [MetricObservation]

    public init(
        timestamp: String,
        host: TelemetryHostContext,
        intervalSeconds: Double,
        collectorOverheadMilliseconds: Double,
        collectorCPUTimeMilliseconds: Double?,
        metrics: [MetricObservation]
    ) {
        self.timestamp = timestamp
        self.host = host
        self.intervalSeconds = intervalSeconds
        self.collectorOverheadMilliseconds = collectorOverheadMilliseconds
        self.collectorCPUTimeMilliseconds = collectorCPUTimeMilliseconds
        self.metrics = metrics
    }
}

public struct TelemetryHostContext: Codable, Sendable {
    public let operatingSystemVersion: String
    public let operatingSystemBuild: String?
    public let architecture: String
    public let modelIdentifier: String?
    public let processorName: String?

    public init(
        operatingSystemVersion: String,
        operatingSystemBuild: String?,
        architecture: String,
        modelIdentifier: String?,
        processorName: String?
    ) {
        self.operatingSystemVersion = operatingSystemVersion
        self.operatingSystemBuild = operatingSystemBuild
        self.architecture = architecture
        self.modelIdentifier = modelIdentifier
        self.processorName = processorName
    }
}
