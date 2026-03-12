import SwiftUI

struct SummaryHeroCard: View {
    let activeCount: Int
    let expiredCount: Int
    let dueTodayCount: Int
    let upcomingCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(riskTitle, systemImage: riskIcon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(AppTheme.glassFill, in: Capsule(style: .continuous))

                    Text("到期事项概览")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))

                    Text(summaryTitle)
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 16)

                Image(systemName: riskIcon)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 52, height: 52)
                    .background(AppTheme.glassStrongFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(AppTheme.glassStroke)
                    }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metric(
                    title: "总事项",
                    value: "\(activeCount)",
                    icon: "tray.full",
                    accent: .white
                )
                metric(
                    title: "已过期",
                    value: "\(expiredCount)",
                    icon: "exclamationmark.triangle.fill",
                    accent: AppTheme.warmRosewood.opacity(0.96)
                )
                metric(
                    title: "今天到期",
                    value: "\(dueTodayCount)",
                    icon: "clock.badge.exclamationmark.fill",
                    accent: AppTheme.warmTerracotta.opacity(0.96)
                )
                metric(
                    title: "7 天内",
                    value: "\(upcomingCount)",
                    icon: "calendar.badge.clock",
                    accent: AppTheme.warmSand.opacity(0.96)
                )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(heroGradient, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(AppTheme.glassHighlight)
                .frame(width: 138, height: 138)
                .offset(x: 34, y: -42)
        }
        .shadow(color: heroShadowColor.opacity(0.28), radius: 22, x: 0, y: 14)
    }

    private var summaryTitle: String {
        if expiredCount > 0 {
            return "当前有 \(expiredCount) 项已过期，建议先处理高风险事项"
        }
        if dueTodayCount > 0 {
            return "今天有 \(dueTodayCount) 项需要优先处理"
        }
        if upcomingCount > 0 {
            return "接下来 7 天有 \(upcomingCount) 项临近到期"
        }
        return "最近没有紧急事项，继续保持"
    }

    private var riskTitle: String {
        if expiredCount > 0 {
            return "高风险提醒"
        }
        if dueTodayCount > 0 {
            return "今日优先"
        }
        if upcomingCount > 0 {
            return "近期关注"
        }
        return "状态稳定"
    }

    private var riskIcon: String {
        if expiredCount > 0 {
            return "exclamationmark.triangle.fill"
        }
        if dueTodayCount > 0 {
            return "bell.and.waves.left.and.right.fill"
        }
        if upcomingCount > 0 {
            return "calendar.badge.clock"
        }
        return "checkmark.seal.fill"
    }

    private var heroGradient: LinearGradient {
        if expiredCount > 0 {
            return LinearGradient(
                colors: [AppTheme.warmRosewood.opacity(0.96), AppTheme.warmTerracotta.opacity(0.88), AppTheme.warmSand.opacity(0.76)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if dueTodayCount > 0 {
            return LinearGradient(
                colors: [AppTheme.warmTerracotta.opacity(0.94), AppTheme.warmSand.opacity(0.86), AppTheme.warmOlive.opacity(0.74)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if upcomingCount > 0 {
            return LinearGradient(
                colors: [Color.accentColor.opacity(0.94), AppTheme.warmSage.opacity(0.84), AppTheme.warmOlive.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [AppTheme.warmSage.opacity(0.86), AppTheme.warmOlive.opacity(0.80), AppTheme.warmSand.opacity(0.66)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroShadowColor: Color {
        if expiredCount > 0 { return AppTheme.warmRosewood }
        if dueTodayCount > 0 { return AppTheme.warmTerracotta }
        if upcomingCount > 0 { return AppTheme.warmSage }
        return AppTheme.warmOlive
    }

    private func metric(title: String, value: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Label(title, systemImage: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)

                Spacer(minLength: 8)
            }

            Text(value)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.9)

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.glassFill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .appAccentGlow(accent, width: 68, height: 68, opacity: 0.12, x: 10, y: -14, blur: 18)
    }
}
