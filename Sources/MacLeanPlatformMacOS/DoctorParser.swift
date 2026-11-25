import Foundation

let allowedProfileFields: [String: ProfileField] = [
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

let profilerTypesToProbe = [
    "SPHardwareDataType",
    "SPDisplaysDataType",
    "SPPowerDataType",
    "SPThunderboltDataType",
    "SPiBridgeDataType",
    "SPPCIDataType"
]

let toolPaths: [(String, String)] = [
    ("system_profiler", "/usr/sbin/system_profiler"),
    ("sysctl", "/usr/sbin/sysctl"),
    ("pmset", "/usr/bin/pmset"),
    ("powermetrics", "/usr/bin/powermetrics"),
    ("ioreg", "/usr/sbin/ioreg"),
    ("sw_vers", "/usr/bin/sw_vers"),
    ("uname", "/usr/bin/uname")
]

func normalized(_ value: String) -> String {
    String(value.lowercased().filter { $0.isLetter || $0.isNumber })
}

func parseProfile(_ output: String) -> ProfileFacts {
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

func parseBatteryStatus(_ output: String) -> (source: String?, percent: String?, state: String?) {
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

func parseThunderboltTopology(_ output: String) -> (controllerCount: Int, portCount: Int)? {
    guard let data = output.data(using: .utf8),
          let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let controllers = root["SPThunderboltDataType"] as? [[String: Any]] else {
        return nil
    }

    let receptacleKeys = ["receptacle_1_tag", "receptacle_2_tag"]
    let portCount = controllers.reduce(into: 0) { count, controller in
        count += receptacleKeys.reduce(into: 0) { portCount, key in
            if controller[key] is [String: Any] { portCount += 1 }
        }
    }
    return (controllers.count, portCount)
}

func firstMatch(_ pattern: String, in value: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(value.startIndex..., in: value)
    guard let match = regex.firstMatch(in: value, range: range),
          let capture = Range(match.range(at: 1), in: value) else {
        return nil
    }
    return String(value[capture])
}
