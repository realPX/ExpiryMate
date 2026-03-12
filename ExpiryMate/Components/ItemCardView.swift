import SwiftUI

struct ItemCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppConstants.defaultReminderHourKey, store: AppConstants.sharedDefaults)
    private var defaultReminderHour = AppConstants.defaultReminderHour
    @AppStorage(AppConstants.defaultReminderMinuteKey, store: AppConstants.sharedDefaults)
    private var defaultReminderMinute = AppConstants.defaultReminderMinute

    enum Style {
        case prominent
        case compact
    }

    let item: ExpiryItem
    let style: Style

    var body: some View {
        VStack(alignment: .leading, spacing: containerSpacing) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                    .fill(statusGradient.opacity(colorScheme == .dark ? 0.20 : 0.14))
                    .frame(width: iconSize, height: iconSize)
                    .overlay {
                        Image(systemName: item.category.symbolName)
                            .font(iconFont)
                            .foregroundStyle(item.category.tint)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                            .strokeBorder(statusColor.opacity(colorScheme == .dark ? 0.18 : (style == .prominent ? 0.10 : 0.14)))
                    }

                VStack(alignment: .leading, spacing: titleBlockSpacing) {
                    HStack(spacing: 8) {
                        CategoryBadge(
                            category: item.category,
                            titleOverride: item.displayCategoryTitle,
                            maxWidth: CategoryBadge.WidthStyle.compact.value
                        )
                        statusBadge
                    }

                    Text(item.title)
                        .font(style == .prominent ? .title3.weight(.semibold) : .headline)
                        .foregroundStyle(.primary)
                        .lineSpacing(style == .prominent ? 2 : 1)
                        .lineLimit(style == .prominent ? 2 : 1)
                        .fixedSize(horizontal: false, vertical: style == .prominent)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(shortStatusText)
                        .font(statusHeaderFont)
                        .foregroundStyle(statusColor)
                    Text(item.expireDate.formatted(AppFormatters.shortDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, style == .prominent ? 0 : 10)
                .padding(.vertical, style == .prominent ? 0 : 8)
                .background {
                    if style == .compact {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.controlFill)
                    }
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
                    .lineSpacing(3)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(cardPadding)
        .background(alignment: .topTrailing) {
            if style == .prominent {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(statusColor.opacity(colorScheme == .dark ? 0.24 : 0.18))
                    .frame(width: 90, height: 32)
                    .blur(radius: 18)
                    .offset(x: 24, y: -8)
                }
        }
        .appCard(radius: style == .prominent ? AppTheme.cardRadius : 22)
        .appAccentGlow(
            statusColor,
            width: style == .prominent ? 76 : 58,
            height: style == .prominent ? 76 : 58,
            opacity: style == .prominent ? 0.11 : 0.08,
            x: style == .prominent ? 12 : 8,
            y: style == .prominent ? -14 : -10,
            blur: style == .prominent ? 20 : 16
        )
    }

    private var shortStatusText: String {
        AppFormatters.countdownText(daysRemaining: item.daysRemaining)
    }

    private var reminderShortText: String {
        if item.reminderPresets.count > 1 {
            return "\(observedReminderTimeText) · \(item.reminderPresets.count) 个提醒"
        }

        if let first = item.reminderPresets.first {
            return "\(observedReminderTimeText) · \(first.title)"
        }

        return observedReminderTimeText
    }

    private var reminderText: String {
        item.reminderEnabled ? reminderShortText : "未开启"
    }

    private var reminderIcon: String {
        item.reminderEnabled ? "bell.badge" : "bell.slash"
    }

    private var observedReminderTimeText: String {
        AppFormatters.reminderTimeText(
            hour: defaultReminderHour,
            minute: defaultReminderMinute
        )
    }

    private var containerSpacing: CGFloat {
        style == .prominent ? 14 : 12
    }

    private var cardPadding: CGFloat {
        style == .prominent ? 18 : 16
    }

    private var iconSize: CGFloat {
        style == .prominent ? 46 : 42
    }

    private var iconCornerRadius: CGFloat {
        style == .prominent ? 18 : 15
    }

    private var iconFont: Font {
        style == .prominent ? .headline.weight(.semibold) : .subheadline.weight(.semibold)
    }

    private var titleBlockSpacing: CGFloat {
        style == .prominent ? 8 : 6
    }

    private var statusHeaderFont: Font {
        style == .prominent ? .subheadline.weight(.semibold) : .caption.weight(.bold)
    }

    private var statusColor: Color {
        if item.isArchived { return .secondary }
        if item.isExpired { return AppTheme.softDanger }
        if item.isDueToday { return AppTheme.softWarning }
        if item.isUpcoming { return item.category.tint }
        return .secondary
    }

    private var statusGradient: LinearGradient {
        let colors: [Color]

        if item.isArchived {
            colors = [Color.secondary.opacity(0.75), Color.secondary.opacity(0.28)]
        } else if item.isExpired {
            colors = [AppTheme.softDanger.opacity(0.94), AppTheme.warmTerracotta.opacity(0.62)]
        } else if item.isDueToday {
            colors = [AppTheme.softWarning.opacity(0.92), AppTheme.warmSand.opacity(0.64)]
        } else if item.isUpcoming {
            colors = [item.category.tint.opacity(0.92), AppTheme.warmOlive.opacity(0.54)]
        } else {
            colors = [Color.accentColor.opacity(0.74), AppTheme.warmSage.opacity(0.44)]
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
        CGFloat(item.timelineProgress)
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

        return item.timelineSummaryText
    }

    private var statusBadge: some View {
        Text(statusBadgeTitle)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(statusColor.opacity(colorScheme == .dark ? 0.18 : 0.12), in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(statusColor.opacity(colorScheme == .dark ? 0.16 : 0.10))
            }
    }

    private func statusPill(text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(style == .prominent ? .caption.weight(.medium) : .caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, style == .prominent ? 10 : 9)
            .padding(.vertical, style == .prominent ? 8 : 7)
            .background(AppTheme.controlFill, in: Capsule(style: .continuous))
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
