import SwiftUI

public struct NeonParticleBackgroundView: View {
    private let theme = NeonThemeEngine.shared
    
    @State private var particles: [NeonParticle] = (0..<40).map { _ in NeonParticle.random() }
    @State private var animationTrigger: Bool = false
    
    public init() {}
    
    public var body: some View {
        Canvas { context, size in
            // Dark Grid Lines
            let gridSpacing: CGFloat = 50
            for x in stride(from: 0, through: size.width, by: gridSpacing) {
                var gridLine = Path()
                gridLine.move(to: CGPoint(x: x, y: 0))
                gridLine.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(gridLine, with: .color(Color(hex: theme.currentPalette.primaryHex).opacity(0.06)), lineWidth: 0.5)
            }
            for y in stride(from: 0, through: size.height, by: gridSpacing) {
                var gridLine = Path()
                gridLine.move(to: CGPoint(x: 0, y: y))
                gridLine.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(gridLine, with: .color(Color(hex: theme.currentPalette.primaryHex).opacity(0.06)), lineWidth: 0.5)
            }
            
            // Floating particles
            for particle in particles {
                let rect = CGRect(
                    x: particle.position.x * size.width,
                    y: particle.position.y * size.height,
                    width: particle.radius * 2,
                    height: particle.radius * 2
                )
                
                let color: Color
                switch particle.colorTier {
                case 0: color = Color(hex: theme.currentPalette.primaryHex)
                case 1: color = Color(hex: theme.currentPalette.secondaryHex)
                case 2: color = Color(hex: theme.currentPalette.tertiaryHex)
                default: color = Color(hex: theme.currentPalette.quaternaryHex)
                }
                
                context.fill(
                    Circle().path(in: rect),
                    with: .color(color.opacity(particle.opacity))
                )
                
                // Glow halo
                let haloRect = rect.insetBy(dx: -particle.radius, dy: -particle.radius)
                context.fill(
                    Circle().path(in: haloRect),
                    with: .color(color.opacity(particle.opacity * 0.15))
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in particles.indices {
                particles[i].position.y -= particles[i].speed * 0.002
                particles[i].position.x += sin(particles[i].position.y * 20) * 0.001
                if particles[i].position.y < -0.05 {
                    particles[i] = NeonParticle.random()
                    particles[i].position.y = 1.05
                }
            }
        }
    }
}

struct NeonParticle {
    var position: CGPoint
    var radius: CGFloat
    var opacity: Double
    var speed: CGFloat
    var colorTier: Int
    
    static func random() -> NeonParticle {
        NeonParticle(
            position: CGPoint(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1)
            ),
            radius: CGFloat.random(in: 1.5...4),
            opacity: Double.random(in: 0.2...0.7),
            speed: CGFloat.random(in: 0.3...1.5),
            colorTier: Int.random(in: 0...3)
        )
    }
}
