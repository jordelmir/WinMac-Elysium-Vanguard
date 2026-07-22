import SwiftUI
import ElysiumCore

public struct SettingsView: View {
    private let theme = NeonThemeEngine.shared
    
    @State private var wineInstalls: [WineInstallation] = []
    @State private var selectedWineSource: WineBinarySource? = nil
    @State private var hardwareProfile = HardwareProbe.shared.detectProfile()
    
    @State private var customPrimaryHex: String = "#00F0FF"
    @State private var customSecondaryHex: String = "#FF007F"
    @State private var customTertiaryHex: String = "#39FF14"
    @State private var customQuaternaryHex: String = "#FF6600"
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // ── SECTION 1: HARDWARE PROFILE ──────────────────
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
                
                // ── SECTION 2: WINE RUNTIME MANAGER ──────────────
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
                
                // ── SECTION 3: NEON THEME CUSTOMIZER ─────────────
                sectionHeader("NEON THEME CUSTOMIZER (4-TIER)")
                
                NeonGlassCardView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Preset buttons
                        HStack(spacing: 10) {
                            presetButton("Cyberpunk", .cyberpunkDefault)
                            presetButton("Matrix", .matrixGreen)
                            presetButton("Vaporwave", .vaporwave)
                        }
                        
                        Divider().background(theme.primaryColor.opacity(0.2))
                        
                        // Custom hex editors
                        colorHexRow("PRIMARY", $customPrimaryHex, theme.primaryColor)
                        colorHexRow("SECONDARY", $customSecondaryHex, theme.secondaryColor)
                        colorHexRow("TERTIARY", $customTertiaryHex, theme.tertiaryColor)
                        colorHexRow("QUATERNARY", $customQuaternaryHex, theme.quaternaryColor)
                        
                        Button("APPLY CUSTOM PALETTE") {
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
                .frame(width: 90, alignment: .leading)
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
