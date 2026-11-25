import Foundation

enum CapabilityStatus: String, Codable {
    case supported
    case unsupported
    case unknown
    case experimental
}

struct ToolAvailability: Codable {
    let name: String
    let path: String
    let status: CapabilityStatus
}

struct Capability: Codable {
    let id: String
    let status: CapabilityStatus
    let evidence: String
}

struct HardwareSummary: Codable {
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
    var thunderboltControllerCount: Int?
    var thunderboltPortCount: Int?
    var systemThermalState: String
}

struct DoctorReport: Codable {
    let generatedAt: String
    let operatingSystem: String
    let operatingSystemBuild: String?
    let architecture: String
    let hardware: HardwareSummary
    let systemProfilerDataTypes: [String]
    let tools: [ToolAvailability]
    let capabilities: [Capability]
}

enum ProfileField {
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

struct ProfileFacts {
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
