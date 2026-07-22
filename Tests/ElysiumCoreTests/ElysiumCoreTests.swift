import XCTest
@testable import ElysiumCore

final class ElysiumCoreTests: XCTestCase {
    func testHardwareProbe() throws {
        let profile = HardwareProbe.shared.detectProfile()
        XCTAssertFalse(profile.gpuName.isEmpty)
        XCTAssertTrue(profile.cpuArch.rawValue.contains("Apple") || profile.cpuArch.rawValue.contains("Intel"))
    }
    
    func testBottleCreation() throws {
        let dummyMeta = ExecutableMetadata(
            url: URL(fileURLWithPath: "/tmp/dummy_game.exe"),
            relativePath: "dummy_game.exe",
            fileName: "dummy_game.exe",
            detectedGraphicsAPI: "DirectX 11 (D3D11)",
            is64Bit: true,
            score: 100
        )
        
        let bottle = try BottleManager.shared.createMicroBottle(for: "UnitTestGame", exeMetadata: dummyMeta)
        XCTAssertEqual(bottle.name, "UnitTestGame")
        XCTAssertTrue(FileManager.default.fileExists(atPath: bottle.bottlePath.path))
    }
    
    func testGameEngineDetection() throws {
        let dummyFolder = URL(fileURLWithPath: "/tmp/dummy_ue5_game")
        let tuning = GameEngineProfileDetector.shared.detectEngine(in: dummyFolder, mainExeName: "UnrealGame.exe")
        XCTAssertNotNil(tuning.recommendedEnv["WINEESYNC"])
    }
    
    func testShaderCacheManager() throws {
        let env = ShaderCacheManager.shared.prepareShaderCache(for: "Cyberpunk2077")
        XCTAssertEqual(env["DXVK_STATE_CACHE"], "1")
        XCTAssertNotNil(env["DXVK_STATE_CACHE_PATH"])
    }
}
