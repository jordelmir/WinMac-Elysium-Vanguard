import Foundation
import ElysiumCore

print("🌌 ====================================================== 🌌")
print("⚡      WINMAC ELYSIUM VANGUARD - ENGINE INITIALIZER      ⚡")
print("🌌 ====================================================== 🌌")

let profile = HardwareProbe.shared.detectProfile()
print("💻 CPU Architecture   : \(profile.cpuArch.rawValue)")
print("🎮 GPU Device        : \(profile.gpuName)")
print("🛡  Metal 3 Support   : \(profile.isMetal3Supported ? "YES (Optimal)" : "NO (Legacy Mode)")")
print("🔥 Target Pipeline   : \(profile.recommendedPipeline.rawValue)")
print("🌌 System ready for Next-Gen 1-Click Game Launch execution.")
