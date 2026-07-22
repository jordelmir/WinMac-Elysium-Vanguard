import SwiftUI
import ElysiumCore

public struct SettingsView: View {
    private let theme = NeonThemeEngine.shared
    
    @State private var wineInstalls: [WineInstallation] = []
    @State private var selectedWineSource: WineBinarySource? = nil
    @State private var hardwareProfile = HardwareProbe.shared.detectProfile()
    
    // ── Graphics & Container Configuration State ──
    @State private var selectedResolution: String = "1280x720"
    @State private var gpuSpoofing: String = "Off"
    @State private var isMangoHUDEnabled: Bool = false
    @State private var dxPerformancePanel: String = "Disable"
    @State private var isWindowManagerDisabled: Bool = false
    @State private var isImageEnhancerDisabled: Bool = false
    @State private var gpuDriver: String = "Builtin Apple Metal (wined3d)"
    @State private var dxvkVersion: String = "wined3d (Native Wine D3D9)"
    @State private var vkd3dVersion: String = "vkd3d-proton-2.14.1"
    @State private var vramLimit: String = "Unlimited"
    
    @State private var customPrimaryHex: String = "#0088FF"
    @State private var customSecondaryHex: String = "#00FFCC"
    @State private var customTertiaryHex: String = "#39FF14"
    @State private var customQuaternaryHex: String = "#FF4500"
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // ── SECTION 1: GRAPHICS & CONTAINER CONFIGURATION ──────────────────
                sectionHeader("GRAPHICS ENGINE & CONTAINER CONFIGURATION")
                
                NeonGlassCardView {
                    VStack(alignment: .leading, spacing: 14) {
                        pickerRow("Game resolution", $selectedResolution, ["1280x720", "1920x1080", "2560x1440", "Native Windowed"])
                        pickerRow("GPU model spoofing", $gpuSpoofing, ["Off", "NVIDIA GeForce RTX 3080", "AMD Radeon RX 6900 XT", "NVIDIA GeForce GTX 1080"])
                        
                        toggleRow("MangoHUD overlay", $isMangoHUDEnabled)
                        pickerRow("DirectX performance panel", $dxPerformancePanel, ["Disable", "Compact", "Full", "Minimal"])
                        toggleRow("Disable window manager", $isWindowManagerDisabled)
                        toggleRow("Disable image quality enhancement plugin", $isImageEnhancerDisabled)
                        
                        Divider().background(theme.primaryColor.opacity(0.2))
                        
                        pickerRow("GPU driver", $gpuDriver, ["Builtin Apple Metal (wined3d)", "MoltenVK 1.4 Native", "Game Porting Toolkit D3DMetal"])
                        pickerRow("DXVK version", $dxvkVersion, ["wined3d (Native Wine D3D9)", "dxvk-2.3.1-async", "dxvk-1.10.3"])
                        pickerRow("VKD3D version", $vkd3dVersion, ["vkd3d-proton-2.14.1", "vkd3d (Builtin Wine)"])
                        pickerRow("VRAM limit", $vramLimit, ["Unlimited", "2048 MB", "4096 MB", "8192 MB"])
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // ── SECTION 2: HARDWARE DIAGNOSTICS ──────────────────
                sectionHeader("HARDWARE DIAGNOSTICS")
                
                NeonGlassCardView {
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow("CPU Architecture", hardwareProfile.cpuArch.rawValue)
                        infoRow("GPU Device", hardwareProfile.gpuName)
                        infoRow("Metal 3 Support", hardwareProfile.isMetal3Supported ? "YES ✅" : "NO (Legacy)")
                        infoRow("Active Pipeline", hardwareProfile.recommendedPipeline.rawValue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // ── SECTION 3: WINE RUNTIME MANAGER ──────────────
                sectionHeader("WINE RUNTIME MANAGER")
                
                NeonGlassCardView {
                    VStack(alignment: .leading, spacing: 10) {
                        if wineInstalls.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(theme.quaternaryColor)
                                Text("No Wine installations detected on this system.")
                                    .foregroundColor(.gray)
                            }
                            .font(.subheadline)
                        } else {
                            ForEach(wineInstalls, id: \.source) { install in
                                HStack {
                                    Image(systemName: selectedWineSource == install.source ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedWineSource == install.source ? theme.tertiaryColor : .gray)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(install.source.rawValue)
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        Text(install.wineBinaryPath.path)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("v\(install.version)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(theme.primaryColor.opacity(0.15))
                                        .foregroundColor(theme.primaryColor)
                                        .cornerRadius(6)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedWineSource = install.source
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // ── SECTION 4: TACTICAL NEON CUSTOMIZER ──────────
                sectionHeader("TACTICAL NEON CUSTOMIZER (4-TIER)")
                
                NeonGlassCardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            presetButton("Tactical Blue", .tacticalDefault)
                            presetButton("Matrix Green", .matrixGreen)
                            presetButton("Crimson Red", .crimsonVanguard)
                        }
                        
                        Divider().background(theme.primaryColor.opacity(0.2))
                        
                        colorHexRow("PRIMARY (BLUE)", $customPrimaryHex, theme.primaryColor)
                        colorHexRow("SECONDARY (CYAN)", $customSecondaryHex, theme.secondaryColor)
                        colorHexRow("TERTIARY (GREEN)", $customTertiaryHex, theme.tertiaryColor)
                        colorHexRow("QUATERNARY (RED)", $customQuaternaryHex, theme.quaternaryColor)
                        
                        Button("APPLY TACTICAL PALETTE") {
                            theme.setPalette(NeonColorPalette(
                                primaryHex: customPrimaryHex,
                                secondaryHex: customSecondaryHex,
                                tertiaryHex: customTertiaryHex,
                                quaternaryHex: customQuaternaryHex
                            ))
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [theme.primaryColor, theme.secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.black)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
        }
        .onAppear {
            wineInstalls = WineProcessLauncher.shared.discoverWineInstallations()
            selectedWineSource = WineProcessLauncher.shared.selectBestWine()?.source
            customPrimaryHex = theme.currentPalette.primaryHex
            customSecondaryHex = theme.currentPalette.secondaryHex
            customTertiaryHex = theme.currentPalette.tertiaryHex
            customQuaternaryHex = theme.currentPalette.quaternaryHex
        }
    }
    
    // MARK: - UI Component Helpers
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .foregroundColor(theme.primaryColor)
            .tracking(2)
    }
    
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
    
    private func pickerRow(_ label: String, _ selection: Binding<String>, _ options: [String]) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(theme.tertiaryColor)
            .frame(width: 220)
        }
    }
    
    private func toggleRow(_ label: String, _ isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .tint(theme.tertiaryColor)
        }
    }
    
    private func presetButton(_ label: String, _ palette: NeonColorPalette) -> some View {
        Button(label) {
            theme.setPalette(palette)
            customPrimaryHex = palette.primaryHex
            customSecondaryHex = palette.secondaryHex
            customTertiaryHex = palette.tertiaryHex
            customQuaternaryHex = palette.quaternaryHex
        }
        .buttonStyle(.plain)
        .font(.system(size: 11, weight: .bold, design: .monospaced))
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(theme.currentPalette == palette ? theme.primaryColor.opacity(0.3) : Color.white.opacity(0.05))
        .foregroundColor(theme.currentPalette == palette ? theme.primaryColor : .gray)
        .cornerRadius(8)
    }
    
    private func colorHexRow(_ label: String, _ hex: Binding<String>, _ preview: Color) -> some View {
        HStack {
            Circle()
                .fill(preview)
                .frame(width: 14, height: 14)
                .shadow(color: preview, radius: 4)
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 130, alignment: .leading)
            TextField("Hex", text: hex)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 100)
                .padding(4)
                .background(Color.white.opacity(0.05))
                .cornerRadius(6)
        }
    }
}
