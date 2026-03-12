import SwiftUI
import SwiftData
import UIKit
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("showArchivedItems") private var showArchivedItems = true
    @AppStorage("autoArchiveExpiredItems") private var autoArchiveExpiredItems = false
    @AppStorage("groupExpiredItemsSeparately") private var groupExpiredItemsSeparately = true
    @AppStorage(AppConstants.defaultReminderHourKey, store: AppConstants.sharedDefaults)
    private var defaultReminderHour = AppConstants.defaultReminderHour
    @AppStorage(AppConstants.defaultReminderMinuteKey, store: AppConstants.sharedDefaults)
    private var defaultReminderMinute = AppConstants.defaultReminderMinute
    @AppStorage(AppConstants.widgetDisplayCountKey, store: AppConstants.sharedDefaults)
    private var widgetDisplayCount = AppConstants.defaultWidgetDisplayCount

    @Query private var items: [ExpiryItem]

    @State private var isShowingReminderTimeSheet = false
    @State private var isShowingWidgetCountDialog = false
    @State private var draftReminderTime = SettingsView.makeTime(
        hour: AppConstants.defaultReminderHour,
        minute: AppConstants.defaultReminderMinute
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                headerCard
                notificationsSection
                dataSection
                organizationSection
                appearanceSection
                aboutSection
            }
            .padding(AppTheme.pagePadding)
            .padding(.bottom, 24)
        }
        .background(AppTheme.canvasGradient.ignoresSafeArea())
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $isShowingReminderTimeSheet) {
            NavigationStack {
                reminderTimeSheet
            }
            .presentationDetents([.medium])
        }
        .confirmationDialog("桌面组件显示数量", isPresented: $isShowingWidgetCountDialog, titleVisibility: .visible) {
            ForEach(1...3, id: \.self) { count in
                Button("显示最近 \(count) 项") {
                    updateWidgetDisplayCount(count)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("桌面组件会按你的选择展示最近到期的事项数量。")
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label(settingsStatusTitle, systemImage: settingsStatusIcon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(AppTheme.glassFill, in: Capsule(style: .continuous))

                    Text("应用偏好")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text("这里集中放通知、显示和数据相关设置。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Image(systemName: "gearshape.2.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 52, height: 52)
                    .background(AppTheme.glassStrongFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            HStack(spacing: 12) {
                settingsMetric(title: "待处理", value: "\(activeCount)", icon: "tray.full.fill", accent: .white)
                settingsMetric(title: "已过期", value: "\(expiredCount)", icon: "clock.badge.exclamationmark.fill", accent: AppTheme.warmSand.opacity(0.96))
                settingsMetric(title: "已归档", value: "\(archivedCount)", icon: "archivebox.fill", accent: AppTheme.warmMist.opacity(0.94))
            }
        }
        .padding(22)
        .background(settingsGradient, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(AppTheme.glassStroke)
        }
        .shadow(color: settingsShadowColor.opacity(0.24), radius: 18, x: 0, y: 10)
    }

    private var notificationsSection: some View {
        settingsSection(
            title: "提醒",
            subtitle: "和系统通知相关的能力",
            accent: AppTheme.warmTerracotta
        ) {
            settingsActionRow(
                title: "打开系统通知设置",
                subtitle: "检查提醒权限、横幅和声音设置",
                icon: "bell.badge.fill",
                tint: AppTheme.warmTerracotta
            ) {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }

            settingsActionRow(
                title: "默认通知时间",
                subtitle: reminderTimeText,
                icon: "clock.fill",
                tint: AppTheme.warmSage
            ) {
                draftReminderTime = reminderTime
                isShowingReminderTimeSheet = true
            }

            settingsActionRow(
                title: "桌面组件",
                subtitle: widgetDisplayCountText,
                icon: "rectangle.3.group.fill",
                tint: AppTheme.warmRosewood
            ) {
                isShowingWidgetCountDialog = true
            }
        }
    }

    private var dataSection: some View {
        settingsSection(
            title: "数据",
            subtitle: "当前版本先保证本地可用",
            accent: AppTheme.warmSage
        ) {
            settingsInfoRow(
                title: "存储方式",
                value: "本地 SwiftData",
                icon: "internaldrive.fill",
                tint: AppTheme.warmSage
            )

            settingsInfoRow(
                title: "同步能力",
                value: "预留 iCloud 扩展",
                icon: "icloud.fill",
                tint: AppTheme.warmStone
            )
        }
    }

    private var organizationSection: some View {
        settingsSection(
            title: "整理规则",
            subtitle: "控制已过期和归档事项的展示方式",
            accent: expiredCount > 0 ? AppTheme.softDanger : AppTheme.warmStone
        ) {
            toggleRow(
                title: "显示已归档事项",
                subtitle: "在事项页中提供归档视图与恢复入口",
                icon: "archivebox.fill",
                tint: AppTheme.warmStone,
                isOn: $showArchivedItems
            )

            toggleRow(
                title: "分组显示已过期事项",
                subtitle: "在“全部事项”中把过期项目单独分区",
                icon: "square.stack.3d.up.fill",
                tint: AppTheme.warmRosewood,
                isOn: $groupExpiredItemsSeparately
            )

            toggleRow(
                title: "自动归档过期 30 天以上事项",
                subtitle: "下次进入 App 时会自动整理较久未处理的过期项目",
                icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                tint: AppTheme.warmSage,
                isOn: $autoArchiveExpiredItems
            )
        }
    }

    private var appearanceSection: some View {
        settingsSection(
            title: "显示与体验",
            subtitle: "当前已适配深色模式和大部分系统观感",
            accent: colorScheme == .dark ? AppTheme.warmStone : AppTheme.warmSand
        ) {
            settingsInfoRow(
                title: "当前外观",
                value: colorScheme == .dark ? "深色模式" : "浅色模式",
                icon: colorScheme == .dark ? "moon.stars.fill" : "sun.max.fill",
                tint: colorScheme == .dark ? AppTheme.warmStone : AppTheme.warmSand
            )

            settingsInfoRow(
                title: "空状态风格",
                value: "已优化对比和留白",
                icon: "sparkles",
                tint: AppTheme.warmRosewood
            )
        }
    }

    private var aboutSection: some View {
        settingsSection(
            title: "关于",
            subtitle: "当前是可继续扩展的首版脚手架",
            accent: AppTheme.warmSage
        ) {
            settingsInfoRow(
                title: "应用名称",
                value: AppConstants.appName,
                icon: "app.fill",
                tint: AppTheme.warmSage
            )

            settingsInfoRow(
                title: "版本",
                value: "1.0",
                icon: "number.circle.fill",
                tint: AppTheme.warmStone
            )

            settingsInfoRow(
                title: "批量操作",
                value: "支持批量归档、恢复归档与清空归档",
                icon: "ellipsis.circle.fill",
                tint: AppTheme.warmOlive
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("后续规划")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.warmSage)
                Text("当前已经包含首页、列表、详情、编辑、通知和 Widget 基础结构，后续可以继续补图片附件、归档、同步和上架物料。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(AppTheme.stroke)
            }
            .shadow(color: AppTheme.shadow, radius: 16, x: 0, y: 8)
            .appAccentGlow(Color.accentColor, width: 72, height: 72, opacity: 0.08, x: 10, y: -12, blur: 18)
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        subtitle: String,
        accent: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: "sparkles")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(AppTheme.controlStrongFill, in: Capsule(style: .continuous))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(accent.opacity(0.12))
                    }
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                content()
            }
        }
    }

    private var activeCount: Int {
        items.filter { !$0.isArchived && !$0.isExpired }.count
    }

    private var expiredCount: Int {
        items.filter { !$0.isArchived && $0.isExpired }.count
    }

    private var archivedCount: Int {
        items.filter(\.isArchived).count
    }

    private var dueTodayCount: Int {
        items.filter { !$0.isArchived && $0.isDueToday }.count
    }

    private var settingsGradient: LinearGradient {
        if expiredCount > 0 {
            return LinearGradient(
                colors: [AppTheme.warmRosewood.opacity(0.94), AppTheme.warmTerracotta.opacity(0.84), AppTheme.warmSand.opacity(0.70)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if dueTodayCount > 0 {
            return LinearGradient(
                colors: [AppTheme.warmTerracotta.opacity(0.92), AppTheme.warmSand.opacity(0.84), AppTheme.warmOlive.opacity(0.70)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [Color.accentColor.opacity(0.92), AppTheme.warmSage.opacity(0.82), AppTheme.warmOlive.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var settingsShadowColor: Color {
        if expiredCount > 0 { return AppTheme.warmRosewood }
        if dueTodayCount > 0 { return AppTheme.warmTerracotta }
        return AppTheme.warmSage
    }

    private var settingsStatusTitle: String {
        if expiredCount > 0 { return "需要整理" }
        if dueTodayCount > 0 { return "今日关注" }
        return "状态稳定"
    }

    private var settingsStatusIcon: String {
        if expiredCount > 0 { return "exclamationmark.triangle.fill" }
        if dueTodayCount > 0 { return "clock.badge.exclamationmark.fill" }
        return "checkmark.seal.fill"
    }

    private func settingsMetric(title: String, value: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.9)

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.glassFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppTheme.glassStroke)
        }
        .appAccentGlow(accent, width: 66, height: 66, opacity: 0.12, x: 8, y: -12, blur: 18)
    }

    private func settingsInfoRow(
        title: String,
        value: String,
        icon: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 14) {
            iconBadge(systemName: icon, tint: tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppTheme.stroke)
        }
        .shadow(color: AppTheme.shadow, radius: 16, x: 0, y: 8)
        .appAccentGlow(tint, width: 72, height: 72, opacity: 0.08, x: 10, y: -12, blur: 18)
    }

    private func toggleRow(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            iconBadge(systemName: icon, tint: tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppTheme.stroke)
        }
        .shadow(color: AppTheme.shadow, radius: 16, x: 0, y: 8)
        .appAccentGlow(tint, width: 72, height: 72, opacity: 0.08, x: 10, y: -12, blur: 18)
    }

    private func settingsActionRow(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBadge(systemName: icon, tint: tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(tint.opacity(0.9))
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.10), in: Circle())
            }
            .padding(16)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(AppTheme.stroke)
            }
            .shadow(color: AppTheme.shadow, radius: 16, x: 0, y: 8)
            .appAccentGlow(tint, width: 72, height: 72, opacity: 0.08, x: 10, y: -12, blur: 18)
        }
        .buttonStyle(.appPressable)
    }

    private var reminderTimeSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Label("提醒设置", systemImage: "bell.badge.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.accentColor.opacity(0.12), in: Capsule(style: .continuous))
                Text("默认通知时间")
                    .font(.title3.weight(.bold))
                Text("修改后会重新安排所有已开启提醒的事项通知。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("当前选择")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(draftReminderTime.formatted(date: .omitted, time: .shortened))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Image(systemName: "clock.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 42, height: 42)
                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.accentColor.opacity(0.12))
                        }
                }

                DatePicker(
                    "通知时间",
                    selection: $draftReminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .padding(18)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(AppTheme.stroke)
            }
            .shadow(color: AppTheme.shadow, radius: 16, x: 0, y: 8)
            .appAccentGlow(Color.accentColor, width: 86, height: 86, opacity: 0.09, x: 12, y: -16, blur: 20)

            Button("保存通知时间") {
                saveReminderTime()
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.accentColor.opacity(0.24), radius: 14, x: 0, y: 8)

            Spacer(minLength: 0)
        }
        .padding(AppTheme.pagePadding)
        .background(AppTheme.canvasGradient.ignoresSafeArea())
        .navigationTitle("通知时间")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") {
                    isShowingReminderTimeSheet = false
                }
            }
        }
    }

    private var reminderTime: Date {
        Self.makeTime(hour: defaultReminderHour, minute: defaultReminderMinute)
    }

    private var reminderTimeText: String {
        reminderTime.formatted(date: .omitted, time: .shortened)
    }

    private var widgetDisplayCountText: String {
        "显示最近 \(min(max(widgetDisplayCount, 1), 3)) 项"
    }

    private func saveReminderTime() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: draftReminderTime)
        defaultReminderHour = components.hour ?? AppConstants.defaultReminderHour
        defaultReminderMinute = components.minute ?? AppConstants.defaultReminderMinute
        isShowingReminderTimeSheet = false

        Task {
            await NotificationScheduler.shared.syncAll(using: modelContext)
        }
    }

    private func updateWidgetDisplayCount(_ count: Int) {
        widgetDisplayCount = min(max(count, 1), 3)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func makeTime(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? .now
    }

    private func iconBadge(systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.headline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 40, height: 40)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(tint.opacity(0.12))
            }
    }
}
