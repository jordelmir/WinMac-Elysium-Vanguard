import SwiftUI

public enum ElysiumLogoSize {
    case small   // 32x32 for top bar
    case medium  // 64x64 for cards
    case large   // 120x120 for headers
    case hero    // 200x200 for main welcome screen
    
    var dimension: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 64
        case .large: return 120
        case .hero: return 220
        }
    }
}

public struct ElysiumLogoView: View {
    private let size: ElysiumLogoSize
    private let theme = NeonThemeEngine.shared
    
    @State private var isPulsing: Bool = false
    @State private var isHovered: Bool = false
    @State private var rotationAngle: Double = 0
    
    public init(size: ElysiumLogoSize = .medium) {
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Luminous Outer Neon Aura Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.primaryColor.opacity(isPulsing ? 0.6 : 0.2),
                            theme.secondaryColor.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: size.dimension * 0.8
                    )
                )
                .frame(width: size.dimension * 1.5, height: size.dimension * 1.5)
                .blur(radius: 10)
            
            // 3D Metal Ring Border
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            theme.primaryColor,
                            theme.secondaryColor,
                            theme.tertiaryColor,
                            theme.quaternaryColor,
                            theme.primaryColor
                        ],
                        center: .center,
                        angle: .degrees(rotationAngle)
                    ),
                    lineWidth: size == .small ? 1.5 : 3
                )
                .frame(width: size.dimension * 1.08, height: size.dimension * 1.08)
                .shadow(color: theme.primaryColor.opacity(0.8), radius: isHovered ? 12 : 6)
            
            // 3D Vanguard Shield Emblem Image
            if let logoPath = Bundle.module.path(forResource: "elysium_logo", ofType: "jpg"),
               let nsImage = NSImage(contentsOfFile: logoPath) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .frame(width: size.dimension, height: size.dimension)
                    .shadow(color: theme.secondaryColor.opacity(0.8), radius: 15)
            } else {
                // Vector fallback 3D shield if image resource is loading
                ZStack {
                    Circle()
                        .fill(Color.black)
                    Image(systemName: "shield.checkered")
                        .font(.system(size: size.dimension * 0.5, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primaryColor, theme.secondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(Circle())
            }
        }
        .rotation3DEffect(
            .degrees(isHovered ? 15 : 0),
            axis: (x: 0.5, y: 1.0, z: 0.0),
            perspective: 0.6
        )
        .scaleEffect(isHovered ? 1.08 : (isPulsing ? 1.02 : 1.0))
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isHovered)
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            isPulsing = true
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}
