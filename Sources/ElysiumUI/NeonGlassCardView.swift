import SwiftUI

public struct NeonGlassCardView<Content: View>: View {
    private let content: Content
    private let theme = NeonThemeEngine.shared
    
    @State private var isHovered: Bool = false
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        ZStack {
            // Glassmorphic translucent background
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.6))
                )
            
            // Glowing Phosphorescent Border
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            isHovered ? theme.primaryColor : theme.primaryColor.opacity(0.5),
                            isHovered ? theme.secondaryColor : theme.secondaryColor.opacity(0.2),
                            theme.tertiaryColor.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isHovered ? 2 : 1
                )
                .shadow(color: isHovered ? theme.primaryColor.opacity(0.8) : Color.clear, radius: 12, x: 0, y: 0)
            
            content
                .padding(16)
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
