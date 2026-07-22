import SwiftUI

public struct NeonColorPalette: Codable, Equatable {
    public var primaryHex: String
    public var secondaryHex: String
    public var tertiaryHex: String
    public var quaternaryHex: String
    
    /// Tactical Blue & Cyber Amber (Masculine / Tech / Aggressive)
    public static let tacticalDefault = NeonColorPalette(
        primaryHex: "#0088FF",    // Electric Tactical Cobalt Blue
        secondaryHex: "#00FFCC",  // High-Tech Cyan Laser
        tertiaryHex: "#39FF14",   // Phosphorescent Tactical Green
        quaternaryHex: "#FF4500"  // Plasma Orange Red
    )
    
    /// Matrix Tactical Green
    public static let matrixGreen = NeonColorPalette(
        primaryHex: "#00FF41",    // Matrix Cyber Green
        secondaryHex: "#008F11",  // Deep Tactical Forest
        tertiaryHex: "#00F0FF",   // Electric Cyan
        quaternaryHex: "#FFD700"  // Tactical Gold
    )
    
    /// Crimson Flame & Amber
    public static let crimsonVanguard = NeonColorPalette(
        primaryHex: "#FF1E27",    // Crimson Red
        secondaryHex: "#FF5500",  // Fire Orange
        tertiaryHex: "#00E5FF",   // Laser Blue
        quaternaryHex: "#FFD700"  // Tactical Gold
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
            (a, r, g, b) = (255, 0, 136, 255)
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
    
    public var currentPalette: NeonColorPalette = .tacticalDefault
    
    public var primaryColor: Color { Color(hex: currentPalette.primaryHex) }
    public var secondaryColor: Color { Color(hex: currentPalette.secondaryHex) }
    public var tertiaryColor: Color { Color(hex: currentPalette.tertiaryHex) }
    public var quaternaryColor: Color { Color(hex: currentPalette.quaternaryHex) }
    
    private init() {}
    
    public func setPalette(_ palette: NeonColorPalette) {
        self.currentPalette = palette
    }
}
