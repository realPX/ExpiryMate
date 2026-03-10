import SwiftUI

enum AppTheme {
    static let pagePadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
    static let cardRadius: CGFloat = 26
    static let smallRadius: CGFloat = 18
    static let cardSpacing: CGFloat = 16

    static let canvasTop = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1)
            : UIColor.systemBackground
    })

    static let canvasBottom = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.12, blue: 0.18, alpha: 1)
            : UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1)
    })

    static let cardBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.secondarySystemBackground.withAlphaComponent(0.92)
            : UIColor.secondarySystemBackground
    })

    static let surfaceMuted = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.tertiarySystemFill.withAlphaComponent(0.34)
            : UIColor.tertiarySystemFill.withAlphaComponent(0.62)
    })

    static let stroke = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.06)
    })

    static let shadow = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.22)
            : UIColor.black.withAlphaComponent(0.08)
    })

    static let accentGradient = LinearGradient(
        colors: [Color.accentColor, Color.blue.opacity(0.82)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [Color.accentColor.opacity(0.94), Color.blue.opacity(0.82), Color.cyan.opacity(0.58)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let canvasGradient = LinearGradient(
        colors: [canvasTop, canvasBottom],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension View {
    func appCard(radius: CGFloat = AppTheme.cardRadius, fill: Color = AppTheme.cardBackground) -> some View {
        background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppTheme.stroke)
            }
            .shadow(color: AppTheme.shadow, radius: 16, x: 0, y: 8)
    }
}
