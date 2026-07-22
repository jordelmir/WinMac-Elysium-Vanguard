import SwiftUI

public struct NeonColorPalette: Codable, Equatable {
    public var primaryHex: String
    public var secondaryHex: String
    public var tertiaryHex: String
    public var quaternaryHex: String
    
    public static let cyberpunkDefault = NeonColorPalette(
        primaryHex: "#00F0FF",    // Electric Cyan
        secondaryHex: "#FF007F",  // Neon Pink/Magenta
        tertiaryHex: "#39FF14",   // Phosphorescent Lime Green
        quaternaryHex: "#FF6600"  // Plasma Orange
    )
    
    public static let matrixGreen = NeonColorPalette(
        primaryHex: "#00FF41",    // Matrix Green
        secondaryHex: "#008F11",  // Deep Forest Green
        tertiaryHex: "#00FF66",   // Mint Neon
        quaternaryHex: "#CCFF00"  // Acid Yellow
    )
    
    public static let vaporwave = NeonColorPalette(
        primaryHex: "#9B51E0",    // Neon Purple
        secondaryHex: "#00F0FF",  // Electric Blue
        tertiaryHex: "#FF007F",   // Hot Pink
        quaternaryHex: "#F2C94C"  // Gold Sun
    )
}

public extension Color {
    init(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexSanitized.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 240, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

@Observable
public final class NeonThemeEngine {
    public static let shared = NeonThemeEngine()
    
    public var currentPalette: NeonColorPalette = .cyberpunkDefault
    
    public var primaryColor: Color { Color(hex: currentPalette.primaryHex) }
    public var secondaryColor: Color { Color(hex: currentPalette.secondaryHex) }
    public var tertiaryColor: Color { Color(hex: currentPalette.tertiaryHex) }
    public var quaternaryColor: Color { Color(hex: currentPalette.quaternaryHex) }
    
    private init() {}
    
    public func setPalette(_ palette: NeonColorPalette) {
        self.currentPalette = palette
    }
}
