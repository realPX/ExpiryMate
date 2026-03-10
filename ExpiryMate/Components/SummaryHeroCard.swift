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
                        .background(.white.opacity(0.16), in: Capsule(style: .continuous))

                    Text("到期事项概览")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))

                    Text(summaryTitle)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 16)

                Image(systemName: riskIcon)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(12)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                    accent: .red.opacity(0.95)
                )
                metric(
                    title: "今天到期",
                    value: "\(dueTodayCount)",
                    icon: "clock.badge.exclamationmark.fill",
                    accent: .orange.opacity(0.95)
                )
                metric(
                    title: "7 天内",
                    value: "\(upcomingCount)",
                    icon: "calendar.badge.clock",
                    accent: .yellow.opacity(0.95)
                )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(heroGradient, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 138, height: 138)
                .offset(x: 34, y: -42)
        }
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(.white.opacity(0.55))
                .frame(width: 96, height: 4)
                .padding(.top, 12)
                .padding(.leading, 24)
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
                colors: [Color.red.opacity(0.95), Color.orange.opacity(0.82), Color.yellow.opacity(0.54)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if dueTodayCount > 0 {
            return LinearGradient(
                colors: [Color.orange.opacity(0.94), Color.yellow.opacity(0.78), Color.pink.opacity(0.52)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if upcomingCount > 0 {
            return LinearGradient(
                colors: [Color.accentColor.opacity(0.94), Color.blue.opacity(0.82), Color.cyan.opacity(0.58)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [Color.green.opacity(0.84), Color.teal.opacity(0.76), Color.blue.opacity(0.54)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroShadowColor: Color {
        if expiredCount > 0 { return .red }
        if dueTodayCount > 0 { return .orange }
        if upcomingCount > 0 { return .accentColor }
        return .green
    }

    private func metric(title: String, value: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer(minLength: 8)

                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(8)
                    .background(accent.opacity(0.26), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(accent)
                .frame(width: 4)
                .padding(.vertical, 12)
                .padding(.leading, 8)
        }
    }
}
