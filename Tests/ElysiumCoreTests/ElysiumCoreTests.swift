import XCTest
@testable import ElysiumCore

final class ElysiumCoreTests: XCTestCase {
    func testHardwareProbe() throws {
        let profile = HardwareProbe.shared.detectProfile()
        XCTAssertFalse(profile.gpuName.isEmpty)
    }
}
