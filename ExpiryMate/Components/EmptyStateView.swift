import SwiftUI

struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentGradient.opacity(colorScheme == .dark ? 0.18 : 0.12))
                    .frame(width: 68, height: 68)

                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.accentGradient)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
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
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(AppTheme.surfaceMuted.opacity(colorScheme == .dark ? 0.65 : 0.35), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .appCard()
    }
}
