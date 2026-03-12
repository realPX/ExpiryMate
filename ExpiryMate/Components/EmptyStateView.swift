import SwiftUI

struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentGradient.opacity(colorScheme == .dark ? 0.16 : 0.10))
                    .frame(width: 78, height: 78)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.controlStrongFill)
                    .frame(width: 58, height: 58)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(colorScheme == .dark ? AppTheme.glassStroke : Color.accentColor.opacity(0.12))
                    }

                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.accentColor.opacity(0.92))
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text(actionTitle)
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.accentGradient, in: Capsule(style: .continuous))
                    .foregroundStyle(.white)
                    .shadow(color: AppTheme.warmRosewood.opacity(0.16), radius: 12, x: 0, y: 8)
                }
                .buttonStyle(.appPressable)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(alignment: .topTrailing) {
            Circle()
                .fill(AppTheme.warmSand.opacity(colorScheme == .dark ? 0.12 : 0.09))
                .frame(width: 118, height: 118)
                .blur(radius: 24)
                .offset(x: 30, y: -36)
        }
        .appCard(fill: AppTheme.surfaceMuted.opacity(colorScheme == .dark ? 0.82 : 0.35))
    }
}
