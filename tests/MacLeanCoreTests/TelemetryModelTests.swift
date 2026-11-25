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
}
