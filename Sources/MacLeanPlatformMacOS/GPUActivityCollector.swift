import CoreFoundation
import Foundation
import IOKit
import MacLeanCore

struct GPUActivityReading: Equatable, Sendable {
    let driverClass: String
    let utilizationPercent: Double?

    static func parse(driverClass: String, statistics: NSDictionary?) -> GPUActivityReading {
        let number = statistics?["Device Utilization %"] as? NSNumber
        let value = number.flatMap {
            CFGetTypeID($0) == CFBooleanGetTypeID() ? nil : $0.doubleValue
        }
        let validValue = value.flatMap { $0.isFinite && (0...100).contains($0) ? $0 : nil }
        return GPUActivityReading(driverClass: driverClass, utilizationPercent: validValue)
    }
}

public enum MacLeanGPUActivityCollector {
    private static let source =
        "IORegistry IOAccelerator PerformanceStatistics/Device Utilization % (driver-published; not a stable Apple contract)"

    public static func collect() -> [MetricObservation] {
        guard let matching = IOServiceMatching("IOAccelerator") else {
            return metrics(from: [], enumerationUnavailable: true)
        }

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return metrics(from: [], enumerationUnavailable: true)
        }
        defer { IOObjectRelease(iterator) }

        var readings: [GPUActivityReading] = []
        while true {
            let service = IOIteratorNext(iterator)
            if service == 0 { break }
            defer { IOObjectRelease(service) }

            var classBuffer = [CChar](repeating: 0, count: 128)
            let classStatus = IOObjectGetClass(service, &classBuffer)
            let driverClass: String
            if classStatus == KERN_SUCCESS {
                let classBytes = classBuffer.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }
                driverClass = String(decoding: classBytes, as: UTF8.self)
            } else {
                driverClass = "UnknownAccelerator"
            }
            let property = IORegistryEntryCreateCFProperty(
                service,
                "PerformanceStatistics" as CFString,
                kCFAllocatorDefault,
                0
            )
            let statistics = property?.takeRetainedValue() as? NSDictionary
            readings.append(GPUActivityReading.parse(driverClass: driverClass, statistics: statistics))
        }
        return metrics(from: readings)
    }

    static func metrics(
        from readings: [GPUActivityReading],
        enumerationUnavailable: Bool = false
    ) -> [MetricObservation] {
        let grouped = Dictionary(grouping: readings, by: \.driverClass)
        var metrics = grouped.keys.sorted().map { driverClass -> MetricObservation in
            let values = (grouped[driverClass] ?? []).compactMap(\.utilizationPercent)
            let value = values.max()
            return MetricObservation(
                name: "graphics.accelerator.\(metricSuffix(driverClass)).utilization",
                value: value,
                text: driverClass,
                unit: "%",
                source: source,
                quality: value == nil ? .unavailable : .direct,
                unavailableReason: value == nil
                    ? "This accelerator driver did not publish a valid Device Utilization % value."
                    : nil
            )
        }

        let readable = readings.filter { $0.utilizationPercent != nil }
        let activeClasses = Set(readable
            .filter { ($0.utilizationPercent ?? 0) > 0 }
            .map(\.driverClass))
            .sorted()
        let readableClasses = Set(readable.map(\.driverClass))
        let unavailableClasses = Set(readings.map(\.driverClass)).subtracting(readableClasses).sorted()
        if readable.isEmpty {
            metrics.append(unavailable(
                "graphics.activity_observed",
                source: source,
                reason: enumerationUnavailable
                    ? "IOAccelerator services could not be enumerated or exposed no valid utilization values."
                    : "No accelerator published a valid utilization value."
            ))
        } else {
            var activityParts = [activeClasses.isEmpty
                ? "none reported on readable accelerators"
                : "reported by: \(activeClasses.joined(separator: ", "))"]
            if !unavailableClasses.isEmpty {
                activityParts.append("unavailable on: \(unavailableClasses.joined(separator: ", "))")
            }
            metrics.append(MetricObservation(
                name: "graphics.activity_observed",
                text: activityParts.joined(separator: "; "),
                source: "Derived from driver-reported IOAccelerator utilization greater than 0%; activity is not hardware power state.",
                quality: .derived
            ))
        }

        metrics.append(unavailable(
            "graphics.active_device",
            source: "No validated source",
            reason: "GPU utilization can show activity, but it does not establish which GPU is powered or selected by the system."
        ))
        metrics.append(unavailable(
            "graphics.power_state",
            source: "No validated cross-model GPU power-state source",
            reason: "No stable, documented cross-model GPU runtime power-state property has been validated; utilization is not a power-state reading."
        ))
        metrics.append(unavailable(
            "graphics.power",
            source: "No validated GPU power source",
            reason: "No validated live GPU power reading is available from this collector."
        ))
        return metrics
    }

    private static func metricSuffix(_ driverClass: String) -> String {
        let suffix = driverClass
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return suffix.isEmpty ? "unknown_accelerator" : suffix
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
}
