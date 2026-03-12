import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppConstants.defaultReminderHourKey, store: AppConstants.sharedDefaults)
    private var defaultReminderHour = AppConstants.defaultReminderHour
    @AppStorage(AppConstants.defaultReminderMinuteKey, store: AppConstants.sharedDefaults)
    private var defaultReminderMinute = AppConstants.defaultReminderMinute

    let item: ExpiryItem

    @State private var editingItem: ExpiryItem?
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                heroCard

                HStack(spacing: 12) {
                    statCard(
                        title: "到期日期",
                        value: item.expireDate.formatted(AppFormatters.fullDate),
                        icon: "calendar",
                        accent: statusColor
                    )
                    statCard(
                        title: "提醒状态",
                        value: item.reminderEnabled ? "已开启" : "未开启",
                        icon: item.reminderEnabled ? "bell.badge" : "bell.slash",
                        accent: item.reminderEnabled ? item.category.tint : .secondary
                    )
                }

                detailCard(
                    title: "提醒规则",
                    subtitle: "通知会在 \(observedReminderTimeText) 发送",
                    accent: item.reminderEnabled ? item.category.tint : .secondary
                ) {
                    Text(reminderSummaryText)
                        .font(.body)
                        .lineSpacing(4)
                }

                if !item.note.isEmpty {
                    detailCard(
                        title: "备注",
                        subtitle: "补充的说明信息",
                        accent: statusColor
                    ) {
                        Text(item.note)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                }

                VStack(spacing: 12) {
                    Button {
                        editingItem = item
                    } label: {
                        Label("编辑事项", systemImage: "slider.horizontal.3")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .foregroundStyle(.white)
                            .shadow(color: AppTheme.warmRosewood.opacity(0.16), radius: 14, x: 0, y: 8)
                    }
                    .buttonStyle(.appPressable)

                    Button {
                        Task { await toggleArchive() }
                    } label: {
                        Label(item.isArchived ? "恢复到列表" : "归档事项", systemImage: item.isArchived ? "arrow.uturn.backward.circle" : "archivebox")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(AppTheme.stroke)
                            }
                    }
                    .buttonStyle(.appPressable)

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("删除事项", systemImage: "trash")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.softDanger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.destructiveFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(AppTheme.softDanger.opacity(0.22))
                            }
                    }
                    .buttonStyle(.appPressable)
                }
            }
            .padding(AppTheme.pagePadding)
            .padding(.bottom, 24)
        }
        .background(AppTheme.canvasGradient.ignoresSafeArea())
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.warmSage)
        .sheet(item: $editingItem) { target in
            NavigationStack {
                ItemEditorView(item: target)
            }
        }
        .alert("删除这个事项？", isPresented: $showDeleteConfirmation) {
            Button("删除", role: .destructive, action: deleteItem)
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后，对应通知也会一并取消。")
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        statusBadge
                        CategoryBadge(
                            category: item.category,
                            titleOverride: item.displayCategoryTitle,
                            emphasis: true,
                            maxWidth: CategoryBadge.WidthStyle.detail.value
                        )
                    }

                    Text(item.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(AppFormatters.countdownText(daysRemaining: item.daysRemaining))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))
                }

                Spacer(minLength: 12)

                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppTheme.glassFill)

                    Image(systemName: item.category.symbolName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .frame(width: 56, height: 56)
            }

            VStack(alignment: .leading, spacing: 10) {
                progressHeader

                GeometryReader { geometry in
                    let width = max(geometry.size.width, 0)

                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(AppTheme.glassTrack)

                        Capsule(style: .continuous)
                            .fill(AppTheme.glassProgress)
                            .frame(width: max(width * timelineProgress, 10))
                    }
                }
                .frame(height: 10)
            }

            Divider()
                .overlay(AppTheme.glassDivider)

            infoRow(title: "状态", value: item.statusText)
            infoRow(title: "分类", value: item.displayCategoryTitle)
        }
        .padding(22)
        .background(statusGradient, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(AppTheme.glassStroke)
        }
        .shadow(color: statusColor.opacity(0.24), radius: 18, x: 0, y: 10)
    }

    private func statCard(title: String, value: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
            Text(value)
                .font(.headline.weight(.semibold))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppTheme.stroke)
        }
        .shadow(color: AppTheme.shadow, radius: 16, x: 0, y: 8)
        .appAccentGlow(accent, width: 78, height: 78, opacity: 0.10, x: 10, y: -14, blur: 18)
    }

    private func detailCard<Content: View>(
        title: String,
        subtitle: String,
        accent: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .strokeBorder(AppTheme.stroke)
        }
        .shadow(color: AppTheme.shadow, radius: 16, x: 0, y: 8)
        .appAccentGlow(accent, width: 82, height: 82, opacity: 0.10, x: 12, y: -16, blur: 20)
    }

    private var statusColor: Color {
        if item.isArchived { return .secondary }
        if item.isExpired { return AppTheme.softDanger }
        if item.isDueToday { return AppTheme.softWarning }
        if item.isUpcoming { return item.category.tint }
        return .secondary
    }

    private var statusGradient: LinearGradient {
        if item.isArchived {
            return LinearGradient(
                colors: [Color.secondary.opacity(0.82), Color.secondary.opacity(0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if item.isExpired {
            return LinearGradient(
                colors: [AppTheme.softDanger.opacity(0.96), AppTheme.warmTerracotta.opacity(0.84), AppTheme.warmSand.opacity(0.60)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if item.isDueToday {
            return LinearGradient(
                colors: [AppTheme.softWarning.opacity(0.94), item.category.tint.opacity(0.76), AppTheme.warmSand.opacity(0.54)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if item.isUpcoming {
            return LinearGradient(
                colors: [item.category.tint.opacity(0.94), Color.accentColor.opacity(0.76), AppTheme.warmOlive.opacity(0.56)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [Color.accentColor.opacity(0.86), AppTheme.warmSage.opacity(0.76), AppTheme.warmOlive.opacity(0.58)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var timelineProgress: CGFloat {
        CGFloat(item.timelineProgress)
    }

    private var observedReminderTimeText: String {
        AppFormatters.reminderTimeText(
            hour: defaultReminderHour,
            minute: defaultReminderMinute
        )
    }

    private var reminderSummaryText: String {
        guard item.reminderEnabled, !item.reminderPresets.isEmpty else {
            return "未开启提醒"
        }

        let presets = item.reminderPresets.map(\.title).joined(separator: "、")
        return "\(observedReminderTimeText) · \(presets)"
    }

    private var progressHeader: some View {
        HStack {
            Label(progressTitle, systemImage: progressIcon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))

            Spacer()

            Text(progressFootnote)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.82))
        }
    }

    private var progressTitle: String {
        if item.isArchived { return "已完成整理" }
        if item.isExpired { return "已超过到期线" }
        if item.isDueToday { return "今天抵达到期线" }
        if item.isUpcoming { return "正在接近到期线" }
        return "到期进度"
    }

    private var progressIcon: String {
        if item.isArchived { return "archivebox.circle.fill" }
        if item.isExpired { return "flag.pattern.checkered" }
        if item.isDueToday { return "calendar.badge.exclamationmark" }
        if item.isUpcoming { return "figure.walk.motion" }
        return "timeline.selection"
    }

    private var progressFootnote: String {
        if item.isArchived { return "已归档" }
        if item.isExpired { return "已超 \(abs(item.daysRemaining)) 天" }
        if item.isDueToday { return "今天截止" }
        return item.timelineSummaryText
    }

    private var statusBadge: some View {
        Label(statusBadgeTitle, systemImage: statusBadgeIcon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppTheme.glassFill, in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(AppTheme.glassStroke)
            }
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

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.82))
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
    }

    private func deleteItem() {
        NotificationScheduler.shared.cancel(for: item)
        modelContext.delete(item)
        try? modelContext.save()
        WidgetSyncService.sync(using: modelContext)
        dismiss()
    }

    @MainActor
    private func toggleArchive() async {
        if item.isArchived {
            await ItemMaintenanceService.shared.restore(items: [item], using: modelContext)
        } else {
            await ItemMaintenanceService.shared.archive(items: [item], using: modelContext)
        }
    }
}
