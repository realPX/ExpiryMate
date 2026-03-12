import SwiftUI

struct CategoryBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    enum WidthStyle {
        case compact
        case card
        case detail
        case editor

        var value: CGFloat {
            switch self {
            case .compact:
                return 136
            case .card:
                return 152
            case .detail:
                return 168
            case .editor:
                return 192
            }
        }
    }

    let category: ExpiryCategory
    var titleOverride: String? = nil
    var emphasis: Bool = false
    var maxWidth: CGFloat? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.symbolName)
                .font(.caption.weight(.bold))
                .frame(width: 22, height: 22)
                .background(category.tint.opacity(emphasis ? iconBackgroundOpacity : iconSecondaryOpacity), in: Circle())

            Text(titleOverride ?? category.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: maxWidth, alignment: .leading)
        }
        .foregroundStyle(category.tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(category.tint.opacity(emphasis ? backgroundOpacity : secondaryBackgroundOpacity))
        )
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(category.tint.opacity(colorScheme == .dark ? 0.16 : 0.12))
        }
    }

    private var iconBackgroundOpacity: Double {
        colorScheme == .dark ? 0.28 : 0.22
    }

    private var iconSecondaryOpacity: Double {
        colorScheme == .dark ? 0.20 : 0.16
    }

    private var backgroundOpacity: Double {
        colorScheme == .dark ? 0.22 : 0.16
    }

    private var secondaryBackgroundOpacity: Double {
        colorScheme == .dark ? 0.14 : 0.10
    }
}
