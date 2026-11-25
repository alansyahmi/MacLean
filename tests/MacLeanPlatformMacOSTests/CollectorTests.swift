import Foundation
import MacLeanCore
@testable import MacLeanPlatformMacOS
import XCTest

final class CollectorTests: XCTestCase {
    func testSystemProfilerParserKeepsOnlyAllowlistedFields() throws {
        let output = try fixture("system-profiler-sample.txt")
        let facts = parseProfile(output)

        XCTAssertEqual(facts.modelIdentifier, "MacBookPro15,1")
        XCTAssertEqual(facts.processorName, "6-Core Intel Core i7")
        XCTAssertEqual(facts.graphicsDevices, ["Intel UHD Graphics 630", "Radeon Pro 5500M"])
        XCTAssertFalse(String(describing: facts).contains("SHOULD-NOT-BE-CAPTURED"))
    }

    func testBatteryParserReadsOnlyStatusFields() throws {
        let output = try fixture("pmset-battery.txt")
        let battery = parseBatteryStatus(output)

        XCTAssertEqual(battery.source, "Battery")
        XCTAssertEqual(battery.percent, "87%")
        XCTAssertEqual(battery.state, "discharging")
    }

    func testSubprocessTimeoutReturnsUnavailableResult() {
        XCTAssertNil(CommandRunner.run("/bin/sleep", arguments: ["2"], timeoutSeconds: 0.05))
    }

    func testIOPowerSourcesPowerKeepsSignAndRequiresBatteryDischargeState() throws {
        let charging = PowerSourceReading(
            voltageMillivolts: 12_000,
            currentMilliamps: 350,
            state: "AC Power",
            isCharging: true,
            unavailableReason: nil
        )
        XCTAssertEqual(try XCTUnwrap(charging.signedPowerWatts), 4.2, accuracy: 0.0001)
        XCTAssertNil(charging.dischargePowerWatts)

        let discharging = PowerSourceReading(
            voltageMillivolts: 12_000,
            currentMilliamps: -500,
            state: "Battery Power",
            isCharging: false,
            unavailableReason: nil
        )
        XCTAssertEqual(try XCTUnwrap(discharging.signedPowerWatts), -6.0, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(discharging.dischargePowerWatts), 6.0, accuracy: 0.0001)
    }

    func testPowermetricsParserKeepsUnrecognizedFieldsUnavailable() {
        let output = """
        **** Processor usage ****
        Intel energy model derived package power (CPUs+GT+SA): 6.01W
        System Average frequency as fraction of nominal: 99.59% (3485.62 Mhz)
        Package 0 C-state residency: 57.93% (C2: 17.12% C3: 40.81%)
        """
        let metrics = Dictionary(
            uniqueKeysWithValues: MacLeanPowermetricsCollector.parseIntelCPUText(output).map { ($0.name, $0) }
        )

        XCTAssertEqual(metrics["cpu.package_power_estimate"]?.value, 6.01)
        XCTAssertEqual(metrics["cpu.package_power_estimate"]?.quality, .osEstimate)
        XCTAssertEqual(metrics["cpu.frequency"]?.value, 3485.62)
        XCTAssertEqual(metrics["cpu.package_c_state_residency"]?.value, 57.93)
        XCTAssertEqual(metrics["cpu.wakeups"]?.quality, .unavailable)
        XCTAssertNil(metrics["cpu.wakeups"]?.value)
    }

    func testCPUTickOrderCountsIdleAsIdleAndNiceAsBusy() throws {
        let previous = makeCPUTickSnapshot(user: 100, system: 50, idle: 800, nice: 10)
        let current = makeCPUTickSnapshot(user: 110, system: 55, idle: 890, nice: 15)

        XCTAssertEqual(previous.busy, 160)
        XCTAssertEqual(previous.total, 960)
        XCTAssertEqual(
            try XCTUnwrap(MacLeanTelemetrySession.utilizationPercent(from: previous, to: current)),
            20.0 / 110.0 * 100.0,
            accuracy: 0.0001
        )
    }

    func testBatteryEnergyIntegrationUsesActualSampleOffsets() throws {
        let host = TelemetryHostContext(
            operatingSystemVersion: "macOS 26.7.3",
            operatingSystemBuild: "25G342",
            architecture: "x86_64",
            modelIdentifier: "MacBookPro15,1",
            processorName: nil
        )
        func sample(offset: Double, power: Double?) -> BenchmarkSample {
            let observation = MetricObservation(
                name: "battery.discharge_power",
                value: power,
                unit: "W",
                source: "fixture",
                quality: power == nil ? .unavailable : .derived
            )
            let telemetry = TelemetryRecord(
                timestamp: "2026-11-25T00:00:00Z",
                host: host,
                intervalSeconds: 1,
                collectorOverheadMilliseconds: 1,
                collectorCPUTimeMilliseconds: 0.1,
                metrics: [observation]
            )
            return BenchmarkSample(offsetSeconds: offset, telemetry: telemetry)
        }

        let complete = MacLeanBenchmarkRunner.integrateDischargeEnergy(
            samples: [sample(offset: 0, power: 2), sample(offset: 10, power: 2)],
            actualDurationSeconds: 10
        )
        XCTAssertEqual(try XCTUnwrap(complete.wattHours), 2.0 / 360, accuracy: 0.000001)
        XCTAssertEqual(complete.coveredSeconds, 10, accuracy: 0.000001)

        let incomplete = MacLeanBenchmarkRunner.integrateDischargeEnergy(
            samples: [sample(offset: 0, power: nil), sample(offset: 10, power: 2)],
            actualDurationSeconds: 10
        )
        XCTAssertNil(incomplete.wattHours)
        XCTAssertGreaterThanOrEqual(incomplete.unavailableReason?.count ?? 0, 1)
    }

    private func fixture(_ name: String) throws -> String {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures"))
        return try String(contentsOf: url, encoding: .utf8)
    }
}
