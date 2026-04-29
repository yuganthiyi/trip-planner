import SwiftUI

// MARK: - Text Style Modifiers
extension Text {
    func displayLargeStyle() -> Text {
        self.font(VoyaraTypography.displayLarge).foregroundColor(VoyaraColors.text)
    }
    
    func headlineLargeStyle() -> Text {
        self.font(VoyaraTypography.headlineLarge).foregroundColor(VoyaraColors.text)
    }
    
    func bodyLargeStyle() -> Text {
        self.font(VoyaraTypography.bodyLarge).foregroundColor(VoyaraColors.text)
    }
    
    func bodyMediumStyle() -> Text {
        self.font(VoyaraTypography.bodyMedium).foregroundColor(VoyaraColors.text)
    }
    
    func captionStyle() -> Text {
        self.font(VoyaraTypography.captionMedium).foregroundColor(VoyaraColors.textSecondary)
    }
}
