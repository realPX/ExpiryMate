import SwiftUI

struct ItemContextPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    let item: ExpiryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        statusBadge
                        CategoryBadge(
                            category: item.category,
                            titleOverride: item.displayCategoryTitle,
                            emphasis: true,
                            maxWidth: CategoryBadge.WidthStyle.card.value
                        )
                    }

                    Text(item.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(AppFormatters.countdownText(daysRemaining: item.daysRemaining))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(statusColor)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 8) {
                    Text(item.expireDate.formatted(AppFormatters.fullDate))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)

                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(statusGradient.opacity(colorScheme == .dark ? 0.20 : 0.15))

                        Image(systemName: item.category.symbolName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(item.category.tint)
                    }
                    .frame(width: 52, height: 52)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(statusColor.opacity(colorScheme == .dark ? 0.24 : 0.18))
                    }
                }
            }

            HStack(spacing: 8) {
                previewPill(text: item.statusText, icon: "calendar")
                previewPill(text: reminderLabel, icon: reminderIcon)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(timelineTitle, systemImage: timelineIcon)
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
                .frame(height: 10)

                HStack {
                    timelineEdge(text: "创建", value: item.createdAt.formatted(AppFormatters.shortDate))
                    Spacer(minLength: 12)
                    timelineEdge(text: "到期", value: item.expireDate.formatted(AppFormatters.shortDate), alignment: .trailing)
                }
            }
            .padding(14)
            .background(AppTheme.controlStrongFill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            HStack(spacing: 10) {
                previewMetric(title: "到期日", value: item.expireDate.formatted(AppFormatters.shortDate), icon: "calendar.badge.clock")
                previewMetric(title: "提醒", value: reminderMetricText, icon: "bell")
                previewMetric(title: "状态", value: archiveMetricText, icon: archiveMetricIcon)
            }

            if !item.note.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("备注摘要", systemImage: "text.alignleft")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)

                    Text(item.note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.controlStrongFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(18)
        .frame(width: 300, alignment: .leading)
        .background(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(statusGradient.opacity(colorScheme == .dark ? 0.22 : 0.16))
                .frame(height: 112)
        }
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(statusGradient)
                .frame(height: 5)
                .padding(.horizontal, 18)
                .padding(.top, 10)
        }
        .appCard(radius: 26)
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

    private var statusBadgeIcon: String {
        if item.isArchived { return "archivebox.fill" }
        if item.isExpired { return "exclamationmark.triangle.fill" }
        if item.isDueToday { return "clock.badge.exclamationmark.fill" }
        if item.isUpcoming { return "calendar.badge.exclamationmark" }
        return "checkmark.seal.fill"
    }

    private var reminderLabel: String {
        item.isArchived ? "归档中" : reminderMetricText
    }

    private var reminderMetricText: String {
        item.reminderEnabled ? AppFormatters.reminderSummary(for: item) : "未开启"
    }

    private var reminderIcon: String {
        item.isArchived ? "archivebox" : (item.reminderEnabled ? "bell.badge" : "bell.slash")
    }

    private var archiveMetricText: String {
        item.isArchived ? "已归档" : "进行中"
    }

    private var archiveMetricIcon: String {
        item.isArchived ? "archivebox.fill" : "tray.full"
    }

    private var timelineTitle: String {
        if item.isArchived { return "到期时间轴" }
        if item.isExpired { return "已超过到期线" }
        if item.isDueToday { return "今天抵达到期线" }
        if item.isUpcoming { return "正在接近到期线" }
        return "到期进度"
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
        if item.isExpired {
            return "已超 \(abs(item.daysRemaining)) 天"
        }

        if item.isDueToday {
            return "今天截止"
        }

        return item.timelineSummaryText
    }

    private var statusBadge: some View {
        Label(statusBadgeTitle, systemImage: statusBadgeIcon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(statusColor.opacity(colorScheme == .dark ? 0.18 : 0.12), in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(statusColor.opacity(colorScheme == .dark ? 0.16 : 0.10))
            }
    }

    private func previewPill(text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(AppTheme.controlFill, in: Capsule(style: .continuous))
    }

    private func previewMetric(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
        .padding(12)
        .background(AppTheme.controlStrongFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func timelineEdge(text: String, value: String, alignment: HorizontalAlignment = .leading) -> some View {
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
