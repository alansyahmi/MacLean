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

    private func fixture(_ name: String) throws -> String {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures"))
        return try String(contentsOf: url, encoding: .utf8)
    }
}
