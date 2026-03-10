import SwiftUI

struct CategoryBadge: View {
    let category: ExpiryCategory
    var emphasis: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.symbolName)
                .font(.caption.weight(.bold))
                .frame(width: 22, height: 22)
                .background(category.tint.opacity(emphasis ? 0.22 : 0.16), in: Circle())

            Text(category.title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(category.tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(category.tint.opacity(emphasis ? 0.16 : 0.10))
        )
    }
}
