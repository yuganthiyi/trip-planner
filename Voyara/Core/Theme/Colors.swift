import SwiftUI

// MARK: - Color Palette
struct VoyaraColors {
    // Primary Colors
    static let primary = Color(red: 0.2, green: 0.6, blue: 1.0) // Vibrant Blue
    static let primaryLight = Color(red: 0.4, green: 0.75, blue: 1.0)
    static let primaryDark = Color(red: 0.1, green: 0.45, blue: 0.85)
    
    // Secondary Colors
    static let secondary = Color(red: 0.95, green: 0.55, blue: 0.2) // Warm Orange
    static let secondaryLight = Color(red: 1.0, green: 0.7, blue: 0.4)
    static let secondaryDark = Color(red: 0.85, green: 0.4, blue: 0.1)
    
    // Accent Colors
    static let accent = Color(red: 0.2, green: 0.85, blue: 0.6) // Teal
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warning = Color(red: 1.0, green: 0.7, blue: 0.0)
    static let error = Color(red: 1.0, green: 0.3, blue: 0.3)
    
    // Neutral Colors (Light mode)
    static let background = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark 
            ? UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
            : UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0)
    })
    
    static let surface = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1.0)
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    })
    
    static let surfaceVariant = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1.0)
            : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
    })
    
    static let text = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
            : UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
    })
    
    static let textSecondary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
            : UIColor(red: 0.4, green: 0.4, blue: 0.42, alpha: 1.0)
    })
    
    static let divider = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.25, blue: 0.27, alpha: 0.3)
            : UIColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1.0)
    })
    
    // Budget Categories
    static let categoryFood = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let categoryTransport = Color(red: 0.3, green: 0.7, blue: 1.0)
    static let categoryHotel = Color(red: 0.9, green: 0.5, blue: 0.7)
    static let categoryActivity = Color(red: 0.2, green: 0.85, blue: 0.6)
    static let categoryShopping = Color(red: 0.8, green: 0.6, blue: 1.0)
    static let categoryOther = Color(red: 0.7, green: 0.7, blue: 0.7)
    
    // Gradient helpers
    static var primaryGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [primary, primaryDark]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var accentGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [accent, Color(red: 0.15, green: 0.7, blue: 0.5)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var warmGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [secondary, Color(red: 1.0, green: 0.4, blue: 0.3)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var cardGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                primary.opacity(0.08),
                primary.opacity(0.02)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "food & dining", "food", "dining": return categoryFood
        case "transportation", "transport": return categoryTransport
        case "accommodation", "hotel": return categoryHotel
        case "activities", "entertainment": return categoryActivity
        case "shopping": return categoryShopping
        default: return categoryOther
        }
    }
}

// MARK: - Theme
struct VoyaraTheme {
    static let cornerRadius: CGFloat = 16
    static let mediumRadius: CGFloat = 12
    static let smallRadius: CGFloat = 8
    
    // Spacing
    static let spacing2: CGFloat = 2
    static let spacing4: CGFloat = 4
    static let spacing6: CGFloat = 6
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    
    // Shadows
    static let shadowSmall = Shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    static let shadowMedium = Shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
    static let shadowLarge = Shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}
