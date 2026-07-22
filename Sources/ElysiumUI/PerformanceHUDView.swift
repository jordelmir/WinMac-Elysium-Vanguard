import SwiftUI

public struct PerformanceHUDView: View {
    private let theme = NeonThemeEngine.shared
    
    @State private var currentFPS: Int = 118
    @State private var frameTimeMs: Double = 8.4
    @State private var vramUsedMB: Int = 4280
    @State private var activePipelineName: String = "D3DMetal (GPTK 2.0)"
    
    public init(pipelineName: String = "D3DMetal (GPTK 2.0)") {
        self._activePipelineName = State(initialValue: pipelineName)
    }
    
    public var body: some View {
        NeonGlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Circle()
                        .fill(theme.tertiaryColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: theme.tertiaryColor, radius: 4)
                    
                    Text("ELYSIUM HUD ENGINE")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(theme.primaryColor)
                    
                    Spacer()
                    
                    Text(activePipelineName)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(theme.secondaryColor)
                }
                
                Divider()
                    .background(theme.primaryColor.opacity(0.3))
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FPS")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("\(currentFPS)")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundColor(theme.tertiaryColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FRAMETIME")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(String(format: "%.1f ms", frameTimeMs))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.primaryColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VRAM")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("\(vramUsedMB) MB")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.quaternaryColor)
                    }
                }
            }
            .frame(maxWidth: 320)
        }
    }
}
