import Foundation
import ElysiumCore
import ElysiumUI

print("🌌 ==================================================================== 🌌")
print("⚡          WINMAC ELYSIUM VANGUARD - NEXT-GEN RUNTIME ENGINE           ⚡")
print("🌌 ==================================================================== 🌌")

// 1. Hardware Probe
let profile = HardwareProbe.shared.detectProfile()
print("💻 CPU Architecture   : \(profile.cpuArch.rawValue)")
print("🎮 GPU Device        : \(profile.gpuName)")
print("🛡  Metal 3 Support   : \(profile.isMetal3Supported ? "YES (Optimal)" : "NO (Legacy Mode)")")
print("🔥 Target Pipeline   : \(profile.recommendedPipeline.rawValue)\n")

// 2. Neon Theme Engine Readout
let theme = NeonThemeEngine.shared
print("🎨 Active Neon Palette (4-Tier Customizer):")
print("   • Primary (Cyan)        : \(theme.currentPalette.primaryHex)")
print("   • Secondary (Magenta)   : \(theme.currentPalette.secondaryHex)")
print("   • Tertiary (Lime Green) : \(theme.currentPalette.tertiaryHex)")
print("   • Quaternary (Orange)   : \(theme.currentPalette.quaternaryHex)\n")

// 3. Automated 1-Click Game Scanner
let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
print("🔍 Scanning directory for game executables: \(currentDir.path)")

if let detectedGame = ExeScanner.shared.scanGameFolder(at: currentDir) {
    print("✅ Target Executable Found!")
    print("   • Game Executable  : \(detectedGame.fileName)")
    print("   • Relative Path    : \(detectedGame.relativePath)")
    print("   • Graphics API     : \(detectedGame.detectedGraphicsAPI)")
    print("   • Architecture     : \(detectedGame.is64Bit ? "64-Bit (x64)" : "32-Bit (x86)")")
    print("   • Scan Score       : \(detectedGame.score)")
    
    // 4. Create Micro-Bottle
    do {
        let bottle = try BottleManager.shared.createMicroBottle(for: "GearOfWar2_Nativo", exeMetadata: detectedGame)
        print("\n🍾 Micro-Bottle Created Successfully!")
        print("   • Bottle Path      : \(bottle.bottlePath.path)")
        print("   • Target Pipeline  : \(bottle.targetPipeline.rawValue)")
        print("   • Env WINEPREFIX   : \(bottle.environmentVariables["WINEPREFIX"] ?? "")")
    } catch {
        print("❌ Error creating micro-bottle: \(error)")
    }
} else {
    print("ℹ️ No target Windows .exe file found in immediate folder. System ready for drag-and-drop 1-Click Game Launch.")
}

print("\n🌌 System operational. Ready for execution.")
