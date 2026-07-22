import SwiftUI
import ElysiumCore

public struct GameLibraryView: View {
    private let theme = NeonThemeEngine.shared
    
    @State private var hardwareProfile = HardwareProbe.shared.detectProfile()
    @State private var scannedGame: ExecutableMetadata? = nil
    @State private var isScanning: Bool = false
    @State private var activePresetName: String = "Cyberpunk Default"
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Cyberpunk Dark Mesh Background
            LinearGradient(
                colors: [Color.black, Color(hex: "#050B14"), Color(hex: "#0A001A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WINMAC ELYSIUM VANGUARD")
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [theme.primaryColor, theme.secondaryColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Next-Gen 1-Click Game Execution Engine • \(hardwareProfile.cpuArch.rawValue)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Theme Customizer Picker
                    HStack(spacing: 8) {
                        Button("Cyberpunk") {
                            theme.setPalette(.cyberpunkDefault)
                            activePresetName = "Cyberpunk Default"
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(activePresetName == "Cyberpunk Default" ? theme.primaryColor.opacity(0.3) : Color.clear)
                        .cornerRadius(8)
                        .foregroundColor(theme.primaryColor)
                        
                        Button("Matrix") {
                            theme.setPalette(.matrixGreen)
                            activePresetName = "Matrix Green"
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(activePresetName == "Matrix Green" ? theme.tertiaryColor.opacity(0.3) : Color.clear)
                        .cornerRadius(8)
                        .foregroundColor(theme.tertiaryColor)
                        
                        Button("Vaporwave") {
                            theme.setPalette(.vaporwave)
                            activePresetName = "Vaporwave"
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(activePresetName == "Vaporwave" ? theme.secondaryColor.opacity(0.3) : Color.clear)
                        .cornerRadius(8)
                        .foregroundColor(theme.secondaryColor)
                    }
                    .padding(4)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Real-Time Performance HUD Overlay
                PerformanceHUDView(pipelineName: hardwareProfile.recommendedPipeline.rawValue)
                    .padding(.horizontal)
                
                // 1-Click Game Launcher Drop Zone / Card Grid
                VStack(spacing: 16) {
                    NeonGlassCardView {
                        VStack(spacing: 12) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 48))
                                .foregroundColor(theme.primaryColor)
                                .shadow(color: theme.primaryColor, radius: 10)
                            
                            Text("1-CLICK GAME DIRECT LAUNCH")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Drag and drop any extracted Windows game folder or executable here")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Button(action: selectGameFolder) {
                                HStack {
                                    Image(systemName: "folder.badge.plus")
                                    Text("SELECT UNCOMPRESSED GAME FOLDER")
                                }
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(theme.primaryColor)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                                .shadow(color: theme.primaryColor.opacity(0.6), radius: 8)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                    .padding(.horizontal)
                    
                    if let game = scannedGame {
                        NeonGlassCardView {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("DETECTED GAME BINARY")
                                        .font(.caption)
                                        .foregroundColor(theme.secondaryColor)
                                    Text(game.fileName)
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                    Text("API: \(game.detectedGraphicsAPI) • Target: \(hardwareProfile.recommendedPipeline.rawValue)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Button("PLAY NOW") {
                                    // Launch action
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(theme.tertiaryColor)
                                .foregroundColor(.black)
                                .fontWeight(.black)
                                .cornerRadius(10)
                                .shadow(color: theme.tertiaryColor, radius: 10)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private func selectGameFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            if let result = ExeScanner.shared.scanGameFolder(at: url) {
                self.scannedGame = result
            }
        }
    }
}
