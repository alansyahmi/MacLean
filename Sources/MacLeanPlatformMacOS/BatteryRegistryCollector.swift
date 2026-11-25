import CoreFoundation
import Foundation
import IOKit

struct BatteryRegistryReading {
    let voltageMillivolts: Double?
    let currentMilliamps: Double?
    let source: String

    var voltageSource: String { "\(source) Voltage property (mV)" }
    var currentSource: String { "\(source) Amperage property (signed mA)" }

    static let registrySource = "IORegistry IOPMPowerSource"
}

enum MacLeanBatteryRegistryCollector {
    static func readMissing(voltage: Bool, current: Bool) -> BatteryRegistryReading? {
        guard voltage || current,
              let service = uniqueBatteryPowerSource() else { return nil }
        defer { _ = IOObjectRelease(service) }

        let voltageValue = voltage ? unsignedIntegerProperty("Voltage", service: service) : nil
        let currentValue = current ? signedIntegerProperty("Amperage", service: service) : nil
        return BatteryRegistryReading(
            voltageMillivolts: voltageValue.map(Double.init),
            currentMilliamps: currentValue.map(Double.init),
            source: BatteryRegistryReading.registrySource
        )
    }

    private static func uniqueBatteryPowerSource() -> io_service_t? {
        guard let matching = IOServiceMatching("IOPMPowerSource") else { return nil }
        var iterator: io_iterator_t = IO_OBJECT_NULL
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { _ = IOObjectRelease(iterator) }

        var services: [io_service_t] = []
        while true {
            let service = IOIteratorNext(iterator)
            guard service != IO_OBJECT_NULL else { break }
            services.append(service)
            if services.count > 1 {
                services.forEach { _ = IOObjectRelease($0) }
                return nil
            }
        }

        guard let service = services.first,
              booleanProperty("BatteryInstalled", service: service) == true else {
            services.forEach { _ = IOObjectRelease($0) }
            return nil
        }
        return service
    }

    private static func property(_ key: String, service: io_service_t) -> CFTypeRef? {
        IORegistryEntryCreateCFProperty(
            service,
            key as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue()
    }

    private static func booleanProperty(_ key: String, service: io_service_t) -> Bool? {
        guard let value = property(key, service: service),
              CFGetTypeID(value) == CFBooleanGetTypeID(),
              let number = value as? NSNumber else { return nil }
        return number.boolValue
    }

    private static func unsignedIntegerProperty(_ key: String, service: io_service_t) -> UInt32? {
        guard let value = property(key, service: service),
              CFGetTypeID(value) == CFNumberGetTypeID(),
              let number = value as? NSNumber else { return nil }
        let reading = number.uint32Value
        return reading > 0 ? reading : nil
    }

    private static func signedIntegerProperty(_ key: String, service: io_service_t) -> Int32? {
        guard let value = property(key, service: service),
              CFGetTypeID(value) == CFNumberGetTypeID(),
              let number = value as? NSNumber else { return nil }
        return number.int32Value
    }
}
