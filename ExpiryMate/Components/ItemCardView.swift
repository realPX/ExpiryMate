import SwiftUI

struct ItemCardView: View {
    enum Style {
        case prominent
        case compact
    }

    let item: ExpiryItem
    let style: Style

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: style == .prominent ? 18 : 16, style: .continuous)
                    .fill(statusGradient.opacity(0.14))
                    .frame(width: style == .prominent ? 46 : 40, height: style == .prominent ? 46 : 40)
                    .overlay {
                        Image(systemName: item.category.symbolName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(item.category.tint)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        CategoryBadge(category: item.category)
                        statusBadge
                    }

                    Text(item.title)
                        .font(style == .prominent ? .title3.weight(.semibold) : .headline)
                        .foregroundStyle(.primary)
                        .lineLimit(style == .prominent ? 2 : 1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(shortStatusText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(statusColor)
                    Text(item.expireDate.formatted(AppFormatters.shortDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                statusPill(text: item.statusText, icon: "calendar")
                statusPill(text: reminderText, icon: reminderIcon)
            }

            VStack(alignment: .leading, spacing: style == .prominent ? 10 : 8) {
                HStack {
                    Label("到期进度", systemImage: timelineIcon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)

                    Spacer()

                    Text(timelineFootnote)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geometry in
                    let width = max(geometry.size.width, 0)

                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(AppTheme.surfaceMuted)

                        Capsule(style: .continuous)
                            .fill(statusGradient)
                            .frame(width: max(width * timelineProgress, 8))
                    }
                }
                .frame(height: style == .prominent ? 10 : 8)

                if style == .prominent {
                    HStack {
                        timelineDate(text: "创建", value: item.createdAt.formatted(AppFormatters.shortDate))
                        Spacer(minLength: 12)
                        timelineDate(text: "到期", value: item.expireDate.formatted(AppFormatters.shortDate), alignment: .trailing)
                    }
                }
            }

            if !item.note.isEmpty, style == .prominent {
                Text(item.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(style == .prominent ? 18 : 16)
        .appCard(radius: style == .prominent ? AppTheme.cardRadius : 22)
    }

    private var shortStatusText: String {
        AppFormatters.countdownText(daysRemaining: item.daysRemaining)
    }

    private var reminderShortText: String {
        if let first = item.reminderPresets.first {
            return first.title
        }
        return "已提醒"
    }

    private var reminderText: String {
        item.reminderEnabled ? reminderShortText : "未开启"
    }

    private var reminderIcon: String {
        item.reminderEnabled ? "bell.badge" : "bell.slash"
    }

    private var statusColor: Color {
        if item.isArchived { return .secondary }
        if item.isExpired { return .red }
        if item.isDueToday { return .orange }
        if item.isUpcoming { return item.category.tint }
        return .secondary
    }

    private var statusGradient: LinearGradient {
        let colors: [Color]

        if item.isArchived {
            colors = [Color.secondary.opacity(0.75), Color.secondary.opacity(0.28)]
        } else if item.isExpired {
            colors = [Color.red.opacity(0.95), Color.orange.opacity(0.55)]
        } else if item.isDueToday {
            colors = [Color.orange.opacity(0.92), Color.yellow.opacity(0.5)]
        } else if item.isUpcoming {
            colors = [item.category.tint.opacity(0.92), Color.accentColor.opacity(0.5)]
        } else {
            colors = [Color.accentColor.opacity(0.72), Color.blue.opacity(0.36)]
        }

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var statusBadgeTitle: String {
        if item.isArchived { return "已归档" }
        if item.isExpired { return "高风险" }
        if item.isDueToday { return "今天到期" }
        if item.isUpcoming { return "即将到期" }
        return "稳定"
    }

    private var timelineIcon: String {
        if item.isArchived { return "archivebox.circle" }
        if item.isExpired { return "flag.pattern.checkered" }
        if item.isDueToday { return "calendar.badge.exclamationmark" }
        if item.isUpcoming { return "figure.walk.motion" }
        return "timeline.selection"
    }

    private var timelineProgress: CGFloat {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: item.createdAt)
        let end = calendar.startOfDay(for: item.expireDate)
        let now = calendar.startOfDay(for: .now)

        let total = end.timeIntervalSince(start)
        guard total > 0 else {
            return item.daysRemaining <= 0 ? 1 : 0.08
        }

        let elapsed = now.timeIntervalSince(start)
        let progress = elapsed / total
        return min(max(progress, 0.08), 1)
    }

    private var timelineFootnote: String {
        if item.isArchived {
            return "已归档"
        }

        if item.isExpired {
            return "已超 \(abs(item.daysRemaining)) 天"
        }

        if item.isDueToday {
            return "今天截止"
        }

        return "\(Int(timelineProgress * 100))%"
    }

    private var statusBadge: some View {
        Text(statusBadgeTitle)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.12), in: Capsule(style: .continuous))
    }

    private func statusPill(text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.05), in: Capsule(style: .continuous))
    }

    private func timelineDate(text: String, value: String, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}
