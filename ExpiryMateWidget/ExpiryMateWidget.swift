import SwiftUI
import WidgetKit

struct ExpiryWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct ExpiryWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ExpiryWidgetEntry {
        ExpiryWidgetEntry(date: .now, snapshot: previewSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (ExpiryWidgetEntry) -> Void) {
        let snapshot = context.isPreview ? previewSnapshot : WidgetSnapshotStore.load()
        completion(ExpiryWidgetEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ExpiryWidgetEntry>) -> Void) {
        let entry = ExpiryWidgetEntry(date: .now, snapshot: WidgetSnapshotStore.load())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now.addingTimeInterval(7200)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private var previewSnapshot: WidgetSnapshot {
        WidgetSnapshot(
            generatedAt: .now,
            items: [
                .init(id: UUID(), title: "感冒药保质期", categoryRawValue: "foodMedicine", expireDate: .now, daysRemaining: -5),
                .init(id: UUID(), title: "视频会员续费", categoryRawValue: "subscription", expireDate: .now, daysRemaining: 2),
                .init(id: UUID(), title: "驾照换证", categoryRawValue: "document", expireDate: .now, daysRemaining: 11)
            ]
        )
    }
}

struct ExpiryMateWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConstants.widgetKind, provider: ExpiryWidgetProvider()) { entry in
            ExpiryMateWidgetView(entry: entry)
        }
        .configurationDisplayName("到期提醒")
        .description("快速查看最近需要处理的到期事项。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ExpiryMateWidgetView: View {
    let entry: ExpiryWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if displayItems.isEmpty {
                emptyState
            } else if isSmallWidget {
                smallLayout
            } else {
                mediumLayout
            }
        }
        .padding(contentPadding)
        .containerBackground(for: .widget) {
            widgetBackground
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            heroCard(item: primaryItem, compact: true)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(secondaryItems.prefix(2)) { item in
                    compactRow(item: item, prominent: false)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            HStack(alignment: .top, spacing: 8) {
                heroCard(item: primaryItem, compact: false)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(secondaryItems.prefix(2)) { item in
                        compactRow(item: item, prominent: true)
                    }

                    if secondaryItems.isEmpty, hasHiddenItems {
                        moreItemsBadge
                    } else if secondaryItems.isEmpty {
                        compactSummaryCard
                    } else if hasHiddenItems {
                        moreItemsBadge
                    } else {
                        compactSummaryCard
                    }
                }
                .frame(width: 138, alignment: .topLeading)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(WidgetPalette.cardTint.opacity(0.28))
                        .frame(width: 42, height: 42)

                    Image(systemName: "checklist.checked")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(WidgetPalette.ink)
                }

                Text("还没有事项")
                    .font(.system(size: isSmallWidget ? 15 : 16, weight: .bold))
                    .foregroundStyle(WidgetPalette.ink)

                Text("打开 App 添加订阅、证件或保修提醒。")
                    .font(.system(size: isSmallWidget ? 11 : 12, weight: .medium))
                    .foregroundStyle(WidgetPalette.secondaryInk)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WidgetPalette.ink)

                    Text("最近到期")
                        .font(.system(size: isSmallWidget ? 13 : 14, weight: .bold))
                        .foregroundStyle(WidgetPalette.ink)
                }

                Spacer(minLength: 8)

                Text(entry.date.formatted(.dateTime.month().day()))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetPalette.secondaryInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(WidgetPalette.cardFill.opacity(0.86), in: Capsule(style: .continuous))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(WidgetPalette.cardStroke)
                    }
            }

            Text(summaryText)
                .font(.system(size: isSmallWidget ? 10 : 11, weight: .semibold))
                .foregroundStyle(WidgetPalette.ink)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(WidgetPalette.cardFill.opacity(0.9), in: Capsule(style: .continuous))
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(WidgetPalette.cardStroke)
                }
                .padding(.leading, 2)
        }
    }

    private func heroCard(item: WidgetSnapshot.SnapshotItem, compact: Bool) -> some View {
        let theme = theme(for: item)

        return VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            HStack(alignment: .top) {
                categoryBadge(theme: theme, compact: compact)

                Spacer(minLength: 8)

                Text(statusPillText(for: item))
                    .font(.system(size: compact ? 10 : 11, weight: .bold))
                    .foregroundStyle(WidgetPalette.ink)
                    .padding(.horizontal, compact ? 8 : 9)
                    .padding(.vertical, 5)
                    .background(WidgetPalette.cardFill.opacity(0.84), in: Capsule(style: .continuous))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(WidgetPalette.cardStroke)
                    }
            }

            Text(item.title)
                .font(.system(size: compact ? 18 : 18, weight: .bold))
                .foregroundStyle(WidgetPalette.ink)
                .lineLimit(compact ? 2 : 2)
                .minimumScaleFactor(0.86)

            Text(heroSubtitle(for: item))
                .font(.system(size: compact ? 12 : 13, weight: .semibold))
                .foregroundStyle(WidgetPalette.secondaryInk)
                .lineLimit(1)

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text(item.expireDate.formatted(.dateTime.month().day()))
            }
            .font(.system(size: compact ? 11 : 12, weight: .medium))
            .foregroundStyle(WidgetPalette.secondaryInk)

            Spacer(minLength: 0)
        }
        .padding(compact ? 14 : 15)
        .frame(maxWidth: .infinity, minHeight: compact ? 104 : 118, alignment: .topLeading)
        .background(heroGradient(for: item, theme: theme), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(WidgetPalette.cardStroke)
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(WidgetPalette.cardFill.opacity(0.42))
                .frame(width: compact ? 66 : 76, height: compact ? 66 : 76)
                .offset(x: 18, y: -18)
        }
    }

    private func compactRow(item: WidgetSnapshot.SnapshotItem, prominent: Bool) -> some View {
        let theme = theme(for: item)

        return HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(theme.tint.opacity(prominent ? 0.18 : 0.14))
                    .frame(width: prominent ? 32 : 28, height: prominent ? 32 : 28)

                Image(systemName: theme.symbolName)
                    .font(.system(size: prominent ? 14 : 12, weight: .semibold))
                    .foregroundStyle(theme.tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: prominent ? 12 : 11, weight: .semibold))
                    .foregroundStyle(WidgetPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(countdownText(for: item))
                    .font(.system(size: prominent ? 11 : 10, weight: .medium))
                    .foregroundStyle(statusColor(for: item))
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, prominent ? 10 : 8)
        .frame(maxWidth: .infinity, minHeight: prominent ? 58 : 50, alignment: .leading)
        .background(WidgetPalette.cardFill.opacity(prominent ? 0.96 : 0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(WidgetPalette.cardStroke)
        }
    }

    private var compactSummaryCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("查看完整清单")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(WidgetPalette.ink)

            Text("在 App 中管理全部到期事项")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(WidgetPalette.secondaryInk)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WidgetPalette.cardFill.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(WidgetPalette.cardStroke)
        }
    }

    private var moreItemsBadge: some View {
        Text("还有 \(max(entry.snapshot.items.count - displayItems.count, 0)) 项")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(WidgetPalette.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(WidgetPalette.cardFill.opacity(0.82), in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(WidgetPalette.cardStroke)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func categoryBadge(theme: WidgetItemTheme, compact: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: theme.symbolName)
                .font(.system(size: 10, weight: .bold))

            Text(theme.title)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(WidgetPalette.ink)
        .padding(.horizontal, compact ? 9 : 8)
        .padding(.vertical, 6)
        .background(WidgetPalette.cardFill.opacity(0.84), in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(WidgetPalette.cardStroke)
        }
    }

    private var widgetBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    WidgetPalette.backgroundTop,
                    WidgetPalette.backgroundMid,
                    WidgetPalette.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(WidgetPalette.cardTint.opacity(0.28))
                .frame(width: isSmallWidget ? 120 : 150, height: isSmallWidget ? 120 : 150)
                .offset(x: -80, y: 70)

            Circle()
                .fill(WidgetPalette.sageGlow.opacity(0.22))
                .frame(width: isSmallWidget ? 92 : 112, height: isSmallWidget ? 92 : 112)
                .offset(x: 100, y: -62)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [WidgetPalette.cardFill.opacity(0.30), WidgetPalette.cardFill.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(-12))
                .offset(x: 54, y: -84)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(WidgetPalette.shadow.opacity(0.12))
                .blur(radius: 24)
                .offset(x: 44, y: 88)
        }
    }

    private var displayItems: [WidgetSnapshot.SnapshotItem] {
        Array(entry.snapshot.items.prefix(AppConstants.preferredWidgetDisplayCount))
    }

    private var primaryItem: WidgetSnapshot.SnapshotItem {
        displayItems[0]
    }

    private var secondaryItems: [WidgetSnapshot.SnapshotItem] {
        Array(displayItems.dropFirst())
    }

    private var hasHiddenItems: Bool {
        entry.snapshot.items.count > displayItems.count
    }

    private var isSmallWidget: Bool {
        family == .systemSmall
    }

    private var contentPadding: CGFloat {
        isSmallWidget ? 14 : 16
    }

    private var summaryText: String {
        guard !displayItems.isEmpty else {
            return "添加事项后可在这里快速查看提醒"
        }

        let expiredCount = displayItems.filter { $0.daysRemaining < 0 }.count
        let dueTodayCount = displayItems.filter { $0.daysRemaining == 0 }.count

        if expiredCount > 0 {
            return "\(expiredCount) 项已过期，建议优先处理"
        }

        if dueTodayCount > 0 {
            return "今天有 \(dueTodayCount) 项需要处理"
        }

        return "未来 \(max(primaryItem.daysRemaining, 0)) 天内优先事项"
    }

    private func countdownText(for item: WidgetSnapshot.SnapshotItem) -> String {
        switch item.daysRemaining {
        case let value where value < 0:
            return "已过期 \(abs(value)) 天"
        case 0:
            return "今天到期"
        default:
            return "剩余 \(item.daysRemaining) 天"
        }
    }

    private func statusPillText(for item: WidgetSnapshot.SnapshotItem) -> String {
        switch item.daysRemaining {
        case let value where value < 0:
            return "高风险"
        case 0:
            return "今天"
        case 1...3:
            return "紧急"
        default:
            return "待处理"
        }
    }

    private func heroSubtitle(for item: WidgetSnapshot.SnapshotItem) -> String {
        switch item.daysRemaining {
        case let value where value < 0:
            return "已过期 \(abs(value)) 天"
        case 0:
            return "今天到期"
        default:
            return countdownText(for: item)
        }
    }

    private func statusColor(for item: WidgetSnapshot.SnapshotItem) -> Color {
        switch item.daysRemaining {
        case let value where value < 0:
            return WidgetPalette.danger
        case 0:
            return WidgetPalette.terracotta
        case 1...3:
            return WidgetPalette.sand
        default:
            return WidgetPalette.sage
        }
    }

    private func heroGradient(for item: WidgetSnapshot.SnapshotItem, theme: WidgetItemTheme) -> LinearGradient {
        let accent = heroAccentColor(for: item, base: theme.tint)

        return LinearGradient(
            colors: [
                accent.opacity(0.40),
                theme.tint.opacity(0.22),
                WidgetPalette.cardFill.opacity(0.86)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func theme(for item: WidgetSnapshot.SnapshotItem) -> WidgetItemTheme {
        switch item.categoryRawValue {
        case "subscription":
            return .init(title: "订阅", symbolName: "creditcard.fill", tint: Color(red: 0.67, green: 0.57, blue: 0.60))
        case "document":
            return .init(title: "证件", symbolName: "doc.text.fill", tint: Color(red: 0.55, green: 0.63, blue: 0.67))
        case "warranty":
            return .init(title: "保修", symbolName: "checkmark.shield.fill", tint: Color(red: 0.53, green: 0.66, blue: 0.55))
        case "foodMedicine":
            return .init(title: "药品", symbolName: "cross.case.fill", tint: Color(red: 0.79, green: 0.60, blue: 0.44))
        default:
            return .init(title: "自定义", symbolName: "tag.fill", tint: Color(red: 0.53, green: 0.67, blue: 0.63))
        }
    }

    private func heroAccentColor(for item: WidgetSnapshot.SnapshotItem, base: Color) -> Color {
        switch item.daysRemaining {
        case let value where value < 0:
            return WidgetPalette.danger
        case 0:
            return WidgetPalette.terracotta
        case 1...3:
            return WidgetPalette.sand
        default:
            return base
        }
    }
}

private struct WidgetItemTheme {
    let title: String
    let symbolName: String
    let tint: Color
}

private enum WidgetPalette {
    static let backgroundTop = Color(red: 0.96, green: 0.92, blue: 0.87)
    static let backgroundMid = Color(red: 0.89, green: 0.86, blue: 0.79)
    static let backgroundBottom = Color(red: 0.82, green: 0.84, blue: 0.76)

    static let cardFill = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let cardTint = Color(red: 0.90, green: 0.81, blue: 0.69)
    static let cardStroke = Color(red: 0.77, green: 0.71, blue: 0.63).opacity(0.24)

    static let ink = Color(red: 0.29, green: 0.25, blue: 0.22)
    static let secondaryInk = Color(red: 0.42, green: 0.37, blue: 0.33)
    static let shadow = Color(red: 0.38, green: 0.29, blue: 0.24)

    static let sage = Color(red: 0.56, green: 0.66, blue: 0.54)
    static let sageGlow = Color(red: 0.73, green: 0.79, blue: 0.69)
    static let terracotta = Color(red: 0.77, green: 0.59, blue: 0.49)
    static let sand = Color(red: 0.88, green: 0.78, blue: 0.62)
    static let danger = Color(red: 0.67, green: 0.52, blue: 0.45)
}
