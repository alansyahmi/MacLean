import Foundation
import MacLeanCore
import XCTest

final class TelemetryModelTests: XCTestCase {
    func testUnavailableMetricDoesNotInventNumericValue() throws {
        let metric = MetricObservation(
            name: "cpu.frequency",
            source: "powermetrics",
            quality: .unavailable,
            unavailableReason: "Sampler requires elevated privileges."
        )
        let data = try JSONEncoder().encode(metric)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["quality"] as? String, "unavailable")
        XCTAssertNil(object["value"])
        XCTAssertEqual(
            object["unavailableReason"] as? String,
            "Sampler requires elevated privileges."
        )
    }

    func testTelemetryRecordIncludesHostBuildAndSamplingOverhead() throws {
        let record = TelemetryRecord(
            timestamp: "2026-11-25T00:00:00Z",
            host: TelemetryHostContext(
                operatingSystemVersion: "macOS 26.7.3",
                operatingSystemBuild: "25G342",
                architecture: "x86_64",
                modelIdentifier: "MacBookPro15,1",
                processorName: nil
            ),
            intervalSeconds: 5,
            collectorOverheadMilliseconds: 12,
            collectorCPUTimeMilliseconds: 2,
            metrics: []
        )
        let data = try JSONEncoder().encode(record)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let host = try XCTUnwrap(object["host"] as? [String: Any])

        XCTAssertEqual(host["operatingSystemBuild"] as? String, "25G342")
        XCTAssertEqual(host["modelIdentifier"] as? String, "MacBookPro15,1")
        XCTAssertEqual(object["collectorOverheadMilliseconds"] as? Double, 12)
        XCTAssertNil(host["serialNumber"])
    }

    func testBenchmarkComparisonUsesMeansAndDoesNotInventPercentForZeroBaseline() {
        func summary(mean: Double) -> BenchmarkMetricSummary {
            BenchmarkMetricSummary(
                name: "cpu.utilization",
                unit: "%",
                sampleCount: 3,
                unavailableSampleCount: 0,
                mean: mean,
                standardDeviation: 1,
                minimum: mean - 1,
                maximum: mean + 1,
                sources: ["Mach"],
                qualities: [.direct]
            )
        }
        func result(id: String, mean: Double, modelIdentifier: String = "MacBookPro15,1") -> BenchmarkResult {
            let host = TelemetryHostContext(
                operatingSystemVersion: "macOS 26.7.3",
                operatingSystemBuild: "25G342",
                architecture: "x86_64",
                modelIdentifier: modelIdentifier,
                processorName: nil
            )
            let energy = BenchmarkEnergySummary(wattHours: nil, coveredSeconds: 0, unavailableReason: "not measured")
            let trial = BenchmarkTrial(
                trialIndex: 1,
                startedAt: "2026-11-25T00:00:00Z",
                endedAt: "2026-11-25T00:01:00Z",
                targetDurationSeconds: 60,
                actualDurationSeconds: 60,
                taskCompletionSeconds: nil,
                samples: [],
                metricSummaries: [
                    summary(mean: mean),
                    BenchmarkMetricSummary(
                        name: "battery.discharge_energy",
                        unit: "Wh",
                        sampleCount: 0,
                        unavailableSampleCount: 1,
                        mean: nil,
                        standardDeviation: nil,
                        minimum: nil,
                        maximum: nil,
                        sources: ["Battery power integration"],
                        qualities: [.unavailable],
                        unavailableReason: "Battery voltage is unavailable."
                    )
                ],
                batteryDischargeEnergy: energy,
                collectorOverheadMilliseconds: 20,
                collectorCPUTimeMilliseconds: 2
            )
            return BenchmarkResult(
                runID: id,
                createdAt: "2026-11-25T00:00:00Z",
                scenario: .desktopIdle,
                workloadDescription: nil,
                host: host,
                samplingIntervalSeconds: 5,
                targetDurationSeconds: 60,
                repetitions: 1,
                privilegedPowermetricsEnabled: false,
                trials: [trial]
            )
        }

        let comparison = BenchmarkComparison(
            baseline: result(id: "baseline", mean: 0),
            candidate: result(id: "candidate", mean: 2)
        )
        let cpuComparison = comparison.metrics.first { $0.name == "cpu.utilization" }
        let energyComparison = comparison.metrics.first { $0.name == "battery.discharge_energy" }
        XCTAssertEqual(cpuComparison?.absoluteChange, 2)
        XCTAssertNil(cpuComparison?.percentChange)
        XCTAssertNotNil(cpuComparison?.unavailableReason)
        XCTAssertEqual(energyComparison?.unavailableReason, "Battery voltage is unavailable.")
        XCTAssertNil(BenchmarkCompatibility.incompatibilityReason(
            baseline: result(id: "baseline", mean: 0),
            candidate: result(id: "candidate", mean: 2)
        ))
        XCTAssertNotNil(BenchmarkCompatibility.incompatibilityReason(
            baseline: result(id: "baseline", mean: 0),
            candidate: result(id: "other-model", mean: 2, modelIdentifier: "MacBookPro16,1")
        ))
    }
}
