import XCTest
@testable import ElysiumCore

final class ElysiumCoreTests: XCTestCase {

    // ── PHASE 1: Hardware & Core ────────────────────────────────
    
    func testHardwareProbeDetectsGPU() throws {
        let profile = HardwareProbe.shared.detectProfile()
        XCTAssertFalse(profile.gpuName.isEmpty, "GPU name must be detected")
    }
    
    func testHardwareProbeDetectsArchitecture() throws {
        let profile = HardwareProbe.shared.detectProfile()
        #if arch(arm64)
        XCTAssertEqual(profile.cpuArch, .appleSilicon)
        XCTAssertEqual(profile.recommendedPipeline, .d3dMetalGPTK)
        #else
        XCTAssertEqual(profile.cpuArch, .intelx86)
        XCTAssertEqual(profile.recommendedPipeline, .dxvkMoltenVK)
        #endif
    }
    
    func testExeScannerIgnoresInstallers() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("ElysiumTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        
        // Create a fake setup.exe (should be ignored)
        try Data([0x4D, 0x5A]).write(to: tmp.appendingPathComponent("setup.exe"))
        // Create a real game exe
        try Data([0x4D, 0x5A]).write(to: tmp.appendingPathComponent("MyGame.exe"))
        
        let result = ExeScanner.shared.scanGameFolder(at: tmp)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fileName, "MyGame.exe")
    }
    
    func testExeScannerReturnsNilForEmptyFolder() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("ElysiumEmpty_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        
        let result = ExeScanner.shared.scanGameFolder(at: tmp)
        XCTAssertNil(result)
    }
    
    // ── PHASE 2: Bottle & Engine ────────────────────────────────
    
    func testBottleCreationWritesConfig() throws {
        let meta = ExecutableMetadata(
            url: URL(fileURLWithPath: "/tmp/test.exe"),
            relativePath: "test.exe",
            fileName: "test.exe",
            detectedGraphicsAPI: "DirectX 11 (D3D11)",
            is64Bit: true,
            score: 100
        )
        let bottle = try BottleManager.shared.createMicroBottle(for: "BottleTest", exeMetadata: meta)
        
        XCTAssertEqual(bottle.name, "BottleTest")
        XCTAssertTrue(FileManager.default.fileExists(atPath: bottle.bottlePath.path))
        
        let configFile = bottle.bottlePath.appendingPathComponent("elysium_config.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: configFile.path), "Config JSON must be persisted")
    }
    
    func testGameEngineDetectionUnrealEngine() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("ElysiumUE_\(UUID().uuidString)")
        let engineDir = tmp.appendingPathComponent("Engine/Binaries", isDirectory: true)
        try FileManager.default.createDirectory(at: engineDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        
        let result = GameEngineProfileDetector.shared.detectEngine(in: tmp, mainExeName: "Game.exe")
        XCTAssertEqual(result.engineType, .unrealEngine)
        XCTAssertTrue(result.supportsMetalFX)
    }
    
    func testGameEngineDetectionUnity() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("ElysiumUnity_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        try Data().write(to: tmp.appendingPathComponent("UnityPlayer.dll"))
        defer { try? FileManager.default.removeItem(at: tmp) }
        
        let result = GameEngineProfileDetector.shared.detectEngine(in: tmp, mainExeName: "Game.exe")
        XCTAssertEqual(result.engineType, .unity)
    }
    
    func testShaderCacheManagerCreatesDirectory() throws {
        let env = ShaderCacheManager.shared.prepareShaderCache(for: "TestGame_\(UUID().uuidString)")
        XCTAssertEqual(env["DXVK_STATE_CACHE"], "1")
        
        let cachePath = env["DXVK_STATE_CACHE_PATH"]!
        XCTAssertTrue(FileManager.default.fileExists(atPath: cachePath))
    }
    
    // ── PHASE 4: Dependency & Patch ─────────────────────────────
    
    func testDependencyInjectorIncludesXACTForDX9() throws {
        let tmp = URL(fileURLWithPath: "/tmp/ElysiumDepTest_\(UUID().uuidString)")
        let deps = try DependencyInjector.shared.resolveDependencies(for: "DirectX 9 (D3D9)", bottlePath: tmp)
        XCTAssertTrue(deps.contains(.xact), "XACT must be included for DX9 games")
        XCTAssertTrue(deps.contains(.vcrun2022), "VC++ Redist always required")
        XCTAssertTrue(deps.contains(.d3dcompiler47), "d3dcompiler_47 always required")
    }
    
    func testDependencyInjectorWritesRegistry() throws {
        let tmp = URL(fileURLWithPath: "/tmp/ElysiumRegTest_\(UUID().uuidString)")
        _ = try DependencyInjector.shared.resolveDependencies(for: "DirectX 11 (D3D11)", bottlePath: tmp)
        
        let regPath = tmp.appendingPathComponent("user.reg")
        XCTAssertTrue(FileManager.default.fileExists(atPath: regPath.path))
        let content = try String(contentsOf: regPath)
        XCTAssertTrue(content.contains("DllOverrides"))
    }
    
    func testGamePatchRegistryCyberpunk() throws {
        let patch = GamePatchRegistry.shared.findPatch(for: "Cyberpunk2077.exe")
        XCTAssertNotNil(patch)
        XCTAssertEqual(patch?.envOverrides["VKD3D_CONFIG"], "dxr11,dxr")
    }
    
    func testGamePatchRegistryGOW2() throws {
        let patch = GamePatchRegistry.shared.findPatch(for: "gow2_main.exe")
        XCTAssertNotNil(patch)
        XCTAssertEqual(patch?.envOverrides["WINEESYNC"], "1")
    }
    
    func testGamePatchRegistryUnknownGameReturnsNil() throws {
        let patch = GamePatchRegistry.shared.findPatch(for: "UnknownGame2099.exe")
        XCTAssertNil(patch)
    }
    
    // ── Wine Discovery ──────────────────────────────────────────
    
    func testWineDiscoveryReturnsArray() throws {
        // On any machine this should not crash; it may return empty
        let installs = WineProcessLauncher.shared.discoverWineInstallations()
        XCTAssertTrue(installs is [WineInstallation])
    }
}
