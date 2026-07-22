import SwiftUI
import ElysiumCore

public struct GameLibraryView: View {
    private let theme = NeonThemeEngine.shared
    
    @State private var hardwareProfile = HardwareProbe.shared.detectProfile()
    @State private var games: [InstalledGameEntry] = []
    @State private var isScanning: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showSettings: Bool = false
    @State private var activePresetName: String = "Cyberpunk"
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Layer 0: Dark gradient base
            LinearGradient(
                colors: [Color.black, Color(hex: "#050B14"), Color(hex: "#0A001A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Layer 1: Animated particle background
            NeonParticleBackgroundView()
            
            // Layer 2: Content
            VStack(spacing: 0) {
                // ── TOP BAR ────────────────────────────────
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                Divider()
                    .background(theme.primaryColor.opacity(0.15))
                
                // ── MAIN CONTENT ───────────────────────────
                if showSettings {
                    SettingsView()
                } else if games.isEmpty {
                    emptyStateView
                } else {
                    gameGridView
                }
            }
        }
        .onAppear {
            games = GameLibraryStore.shared.games
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Logo + Title
            VStack(alignment: .leading, spacing: 2) {
                Text("WINMAC ELYSIUM VANGUARD")
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primaryColor, theme.secondaryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(theme.tertiaryColor)
                        .frame(width: 6, height: 6)
                        .shadow(color: theme.tertiaryColor, radius: 4)
                    
                    Text("\(hardwareProfile.cpuArch.rawValue) • \(hardwareProfile.gpuName) • \(hardwareProfile.recommendedPipeline.rawValue)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Palette switcher
            HStack(spacing: 6) {
                paletteButton("CYB", .cyberpunkDefault, "Cyberpunk")
                paletteButton("MTX", .matrixGreen, "Matrix")
                paletteButton("VPW", .vaporwave, "Vaporwave")
            }
            .padding(3)
            .background(Color.black.opacity(0.5))
            .cornerRadius(10)
            
            // Add game button
            Button(action: selectGameFolder) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("ADD GAME")
                }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(theme.primaryColor)
                .foregroundColor(.black)
                .cornerRadius(8)
                .shadow(color: theme.primaryColor.opacity(0.4), radius: 6)
            }
            .buttonStyle(.plain)
            
            // Settings toggle
            Button(action: { showSettings.toggle() }) {
                Image(systemName: showSettings ? "xmark.circle.fill" : "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(showSettings ? theme.secondaryColor : .gray)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 72))
                .foregroundColor(theme.primaryColor.opacity(0.3))
                .shadow(color: theme.primaryColor.opacity(0.2), radius: 20)
            
            Text("NO GAMES IN LIBRARY")
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Select an uncompressed Windows game folder to begin.")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button(action: selectGameFolder) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                    Text("SELECT GAME FOLDER")
                }
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [theme.primaryColor, theme.secondaryColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.black)
                .cornerRadius(14)
                .shadow(color: theme.primaryColor.opacity(0.5), radius: 12)
            }
            .buttonStyle(.plain)
            
            if let err = errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundColor(theme.quaternaryColor)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Game Grid
    private var gameGridView: some View {
        ScrollView {
            // Performance HUD
            PerformanceHUDView(pipelineName: hardwareProfile.recommendedPipeline.rawValue)
                .padding(.horizontal, 20)
                .padding(.top, 12)
            
            // Game Cards Grid
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 220, maximum: 260), spacing: 16)],
                spacing: 16
            ) {
                ForEach(games) { game in
                    GameCardView(game: game) {
                        launchGame(game)
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Actions
    private func selectGameFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Select Uncompressed Game Folder"
        panel.prompt = "Add Game"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                _ = try GameLibraryStore.shared.addGame(from: url)
                games = GameLibraryStore.shared.games
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func launchGame(_ game: InstalledGameEntry) {
        guard let wine = WineProcessLauncher.shared.selectBestWine() else {
            errorMessage = "No Wine installation found. Install GPTK or Wine via Homebrew."
            return
        }
        
        // Find the bottle config
        // For now, create a fresh config from the stored bottle path
        let bottlePath = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/ElysiumVanguard/Bottles")
        
        let profile = HardwareProbe.shared.detectProfile()
        let config = BottleConfiguration(
            bottleID: game.bottleID ?? UUID(),
            name: game.gameName,
            bottlePath: bottlePath,
            targetPipeline: profile.recommendedPipeline,
            environmentVariables: [:],
            createdDate: Date()
        )
        
        do {
            _ = try WineProcessLauncher.shared.launchGame(
                entry: game,
                bottleConfig: config,
                wine: wine
            )
        } catch {
            errorMessage = "Launch failed: \(error.localizedDescription)"
        }
    }
    
    private func paletteButton(_ label: String, _ palette: NeonColorPalette, _ name: String) -> some View {
        Button(label) {
            theme.setPalette(palette)
            activePresetName = name
        }
        .buttonStyle(.plain)
        .font(.system(size: 10, weight: .bold, design: .monospaced))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(activePresetName == name ? theme.primaryColor.opacity(0.3) : Color.clear)
        .foregroundColor(activePresetName == name ? theme.primaryColor : .gray)
        .cornerRadius(6)
    }
}
