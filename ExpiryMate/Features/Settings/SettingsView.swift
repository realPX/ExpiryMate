import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("showArchivedItems") private var showArchivedItems = true
    @AppStorage("autoArchiveExpiredItems") private var autoArchiveExpiredItems = false
    @AppStorage("groupExpiredItemsSeparately") private var groupExpiredItemsSeparately = true

    @Query private var items: [ExpiryItem]

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
                        .background(.white.opacity(0.16), in: Capsule(style: .continuous))

                    Text("应用偏好")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text("这里集中放通知、显示和数据相关设置。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer(minLength: 12)

                Image(systemName: "gearshape.2.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 52, height: 52)
                    .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            HStack(spacing: 12) {
                settingsMetric(title: "待处理", value: "\(activeCount)", accent: .white)
                settingsMetric(title: "已过期", value: "\(expiredCount)", accent: .red.opacity(0.95))
                settingsMetric(title: "已归档", value: "\(archivedCount)", accent: .brown.opacity(0.95))
            }
        }
        .padding(22)
        .background(settingsGradient, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(.white.opacity(0.55))
                .frame(width: 96, height: 4)
                .padding(.top, 12)
                .padding(.leading, 22)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.12))
        }
        .shadow(color: settingsShadowColor.opacity(0.24), radius: 18, x: 0, y: 10)
    }

    private var notificationsSection: some View {
        settingsSection(
            title: "提醒",
            subtitle: "和系统通知相关的能力",
            accent: .orange
        ) {
            settingsActionRow(
                title: "打开系统通知设置",
                subtitle: "检查提醒权限、横幅和声音设置",
                icon: "bell.badge.fill",
                tint: .orange
            ) {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }

            settingsInfoRow(
                title: "默认通知时间",
                value: "上午 9:00",
                icon: "clock.fill",
                tint: .blue
            )

            settingsInfoRow(
                title: "桌面组件",
                value: "显示最近 1~3 项",
                icon: "rectangle.3.group.fill",
                tint: .purple
            )
        }
    }

    private var dataSection: some View {
        settingsSection(
            title: "数据",
            subtitle: "当前版本先保证本地可用",
            accent: .green
        ) {
            settingsInfoRow(
                title: "存储方式",
                value: "本地 SwiftData",
                icon: "internaldrive.fill",
                tint: .green
            )

            settingsInfoRow(
                title: "同步能力",
                value: "预留 iCloud 扩展",
                icon: "icloud.fill",
                tint: .cyan
            )
        }
    }

    private var organizationSection: some View {
        settingsSection(
            title: "整理规则",
            subtitle: "控制已过期和归档事项的展示方式",
            accent: expiredCount > 0 ? .red : .indigo
        ) {
            toggleRow(
                title: "显示已归档事项",
                subtitle: "在事项页中提供归档视图与恢复入口",
                icon: "archivebox.fill",
                tint: .brown,
                isOn: $showArchivedItems
            )

            toggleRow(
                title: "分组显示已过期事项",
                subtitle: "在“全部事项”中把过期项目单独分区",
                icon: "square.stack.3d.up.fill",
                tint: .pink,
                isOn: $groupExpiredItemsSeparately
            )

            toggleRow(
                title: "自动归档过期 30 天以上事项",
                subtitle: "下次进入 App 时会自动整理较久未处理的过期项目",
                icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                tint: .indigo,
                isOn: $autoArchiveExpiredItems
            )
        }
    }

    private var appearanceSection: some View {
        settingsSection(
            title: "显示与体验",
            subtitle: "当前已适配深色模式和大部分系统观感",
            accent: colorScheme == .dark ? .indigo : .yellow
        ) {
            settingsInfoRow(
                title: "当前外观",
                value: colorScheme == .dark ? "深色模式" : "浅色模式",
                icon: colorScheme == .dark ? "moon.stars.fill" : "sun.max.fill",
                tint: colorScheme == .dark ? .indigo : .yellow
            )

            settingsInfoRow(
                title: "空状态风格",
                value: "已优化对比和留白",
                icon: "sparkles",
                tint: .pink
            )
        }
    }

    private var aboutSection: some View {
        settingsSection(
            title: "关于",
            subtitle: "当前是可继续扩展的首版脚手架",
            accent: .accentColor
        ) {
            settingsInfoRow(
                title: "应用名称",
                value: AppConstants.appName,
                icon: "app.fill",
                tint: .accentColor
            )

            settingsInfoRow(
                title: "版本",
                value: "1.0",
                icon: "number.circle.fill",
                tint: .gray
            )

            settingsInfoRow(
                title: "批量操作",
                value: "支持批量归档、恢复归档与清空归档",
                icon: "ellipsis.circle.fill",
                tint: .teal
            )

            Text("当前已经包含首页、列表、详情、编辑、通知和 Widget 基础结构，后续可以继续补图片附件、归档、同步和上架物料。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        subtitle: String,
        accent: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Label(title, systemImage: "sparkles")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                content()
            }
        }
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(accent.opacity(0.9))
                .frame(width: 44, height: 4)
                .offset(y: -8)
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
                colors: [Color.red.opacity(0.94), Color.orange.opacity(0.8), Color.yellow.opacity(0.46)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if dueTodayCount > 0 {
            return LinearGradient(
                colors: [Color.orange.opacity(0.92), Color.yellow.opacity(0.76), Color.pink.opacity(0.46)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [Color.accentColor.opacity(0.9), Color.blue.opacity(0.76), Color.cyan.opacity(0.46)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var settingsShadowColor: Color {
        if expiredCount > 0 { return .red }
        if dueTodayCount > 0 { return .orange }
        return .accentColor
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

    private func settingsMetric(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(accent)
                .frame(width: 4)
                .padding(.vertical, 10)
                .padding(.leading, 8)
        }
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
                    .font(.headline)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .appCard(radius: 22)
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
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(16)
        .appCard(radius: 22)
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
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .appCard(radius: 22)
        }
        .buttonStyle(.plain)
    }

    private func iconBadge(systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.headline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 40, height: 40)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
