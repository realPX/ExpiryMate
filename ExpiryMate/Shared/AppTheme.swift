import SwiftUI

enum AppTheme {
    static let pagePadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
    static let cardRadius: CGFloat = 26
    static let smallRadius: CGFloat = 18
    static let cardSpacing: CGFloat = 16

    static let warmStone = Color(red: 0.74, green: 0.68, blue: 0.60)
    static let warmSand = Color(red: 0.88, green: 0.78, blue: 0.62)
    static let warmTerracotta = Color(red: 0.77, green: 0.59, blue: 0.49)
    static let warmRosewood = Color(red: 0.67, green: 0.52, blue: 0.45)
    static let warmSage = Color(red: 0.56, green: 0.66, blue: 0.54)
    static let warmOlive = Color(red: 0.68, green: 0.71, blue: 0.58)
    static let warmMist = Color(red: 0.95, green: 0.93, blue: 0.90)
    static let warmIvory = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let softDanger = Color(red: 0.78, green: 0.47, blue: 0.42)
    static let softWarning = Color(red: 0.83, green: 0.63, blue: 0.42)

    static let canvasTop = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.12, blue: 0.11, alpha: 1)
            : UIColor(red: 0.98, green: 0.96, blue: 0.94, alpha: 1)
    })

    static let canvasBottom = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.16, blue: 0.14, alpha: 1)
            : UIColor(red: 0.93, green: 0.93, blue: 0.89, alpha: 1)
    })

    static let cardBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.18, blue: 0.16, alpha: 0.94)
            : UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 0.98)
    })

    static let surfaceMuted = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.30, green: 0.26, blue: 0.23, alpha: 0.48)
            : UIColor(red: 0.95, green: 0.93, blue: 0.90, alpha: 0.88)
    })

    static let stroke = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor(red: 0.74, green: 0.69, blue: 0.63, alpha: 0.18)
    })

    static let shadow = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.24)
            : UIColor(red: 0.39, green: 0.31, blue: 0.26, alpha: 0.08)
    })

    static let glassFill = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.18)
            : UIColor.white.withAlphaComponent(0.14)
    })

    static let glassStrongFill = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.22)
            : UIColor.white.withAlphaComponent(0.18)
    })

    static let glassStroke = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.16)
            : UIColor.white.withAlphaComponent(0.12)
    })

    static let glassAccentLine = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.84)
            : UIColor.white.withAlphaComponent(0.68)
    })

    static let glassHighlight = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.16)
            : UIColor.white.withAlphaComponent(0.12)
    })

    static let glassTrack = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.22)
            : UIColor.white.withAlphaComponent(0.18)
    })

    static let glassProgress = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.92)
            : UIColor.white.withAlphaComponent(0.88)
    })

    static let glassDivider = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.28)
            : UIColor.white.withAlphaComponent(0.22)
    })

    static let controlFill = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.07)
            : UIColor(red: 0.91, green: 0.89, blue: 0.85, alpha: 0.85)
    })

    static let controlStrongFill = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor(red: 0.95, green: 0.93, blue: 0.90, alpha: 0.92)
    })

    static let destructiveFill = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.systemRed.withAlphaComponent(0.16)
            : UIColor(red: 0.86, green: 0.54, blue: 0.48, alpha: 0.14)
    })

    static let handleFill = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.26)
            : UIColor.secondaryLabel.withAlphaComponent(0.28)
    })

    static let accentGradient = LinearGradient(
        colors: [Color.accentColor.opacity(0.96), warmSage.opacity(0.92)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [warmTerracotta.opacity(0.96), warmSand.opacity(0.92), warmOlive.opacity(0.84)],
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

    func appAccentGlow(
        _ tint: Color,
        width: CGFloat = 86,
        height: CGFloat = 86,
        opacity: Double = 0.10,
        x: CGFloat = 18,
        y: CGFloat = -18,
        blur: CGFloat = 22
    ) -> some View {
        overlay(alignment: .topTrailing) {
            Circle()
                .fill(tint.opacity(opacity))
                .frame(width: width, height: height)
                .blur(radius: blur)
                .offset(x: x, y: y)
        }
    }

    func appToolbarCapsule(
        prominent: Bool = false,
        tint: Color = AppTheme.warmStone
    ) -> some View {
        padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                prominent ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.controlStrongFill),
                in: Capsule(style: .continuous)
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(
                        prominent ? AppTheme.glassStroke : tint.opacity(0.12),
                        lineWidth: 1
                    )
            }
    }
}

struct AppPressableButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.98
    var pressedOpacity: Double = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == AppPressableButtonStyle {
    static var appPressable: AppPressableButtonStyle {
        AppPressableButtonStyle()
    }
}
