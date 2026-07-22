import SwiftUI
import ElysiumCore

public struct GameCardView: View {
    private let theme = NeonThemeEngine.shared
    let game: InstalledGameEntry
    let onPlay: () -> Void
    
    @State private var isHovered: Bool = false
    @State private var hoverOffset: CGSize = .zero
    
    public init(game: InstalledGameEntry, onPlay: @escaping () -> Void) {
        self.game = game
        self.onPlay = onPlay
    }
    
    public var body: some View {
        ZStack {
            // Base glass panel
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.black.opacity(0.8), Color(hex: "#0A0A1A").opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            // Neon border glow
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            theme.primaryColor.opacity(isHovered ? 1 : 0.3),
                            theme.secondaryColor.opacity(isHovered ? 0.8 : 0.1),
                            theme.tertiaryColor.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isHovered ? 2 : 1
                )
                .shadow(color: theme.primaryColor.opacity(isHovered ? 0.6 : 0), radius: 20)
            
            VStack(alignment: .leading, spacing: 12) {
                // Game icon zone
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [theme.primaryColor.opacity(0.1), theme.secondaryColor.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                    
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 40))
                        .foregroundColor(theme.primaryColor.opacity(0.6))
                        .shadow(color: theme.primaryColor.opacity(0.4), radius: 10)
                }
                
                // Title
                Text(game.gameName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // Metadata
                HStack(spacing: 6) {
                    Text(game.detectedGraphicsAPI)
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.primaryColor.opacity(0.15))
                        .foregroundColor(theme.primaryColor)
                        .cornerRadius(4)
                    
                    Text(game.is64Bit ? "x64" : "x86")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.tertiaryColor.opacity(0.15))
                        .foregroundColor(theme.tertiaryColor)
                        .cornerRadius(4)
                }
                
                // Engine type
                Text(game.engineType.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                
                // Stats row
                HStack {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.gray)
                    Text("\(game.totalLaunchCount) plays")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    let hours = Int(game.totalPlayTimeSeconds / 3600)
                    Text("\(hours)h played")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // Play Button
                Button(action: onPlay) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("LAUNCH")
                    }
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
                    .shadow(color: theme.primaryColor.opacity(0.5), radius: isHovered ? 12 : 4)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
        .frame(width: 220, height: 340)
        .rotation3DEffect(
            .degrees(isHovered ? 2 : 0),
            axis: (x: hoverOffset.height * 0.01, y: -hoverOffset.width * 0.01, z: 0),
            perspective: 0.5
        )
        .scaleEffect(isHovered ? 1.04 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isHovered)
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                isHovered = true
                hoverOffset = CGSize(width: location.x - 110, height: location.y - 170)
            case .ended:
                isHovered = false
                hoverOffset = .zero
            }
        }
    }
}
