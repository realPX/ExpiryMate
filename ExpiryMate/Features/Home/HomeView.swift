import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedTab: AppTab
    @Binding var selectedCategory: ExpiryCategory?
    let onAddTap: () -> Void

    @Query(sort: [SortDescriptor(\ExpiryItem.expireDate)]) private var items: [ExpiryItem]

    init(
        selectedTab: Binding<AppTab>,
        selectedCategory: Binding<ExpiryCategory?>,
        onAddTap: @escaping () -> Void
    ) {
        _selectedTab = selectedTab
        _selectedCategory = selectedCategory
        self.onAddTap = onAddTap
    }

    private var activeItems: [ExpiryItem] {
        items.filter { !$0.isArchived }.sorted { $0.expireDate < $1.expireDate }
    }

    private var dueTodayItems: [ExpiryItem] {
        activeItems.filter(\.isDueToday)
    }

    private var expiredItems: [ExpiryItem] {
        activeItems.filter(\.isExpired)
    }

    private var upcomingItems: [ExpiryItem] {
        activeItems.filter { (0...7).contains($0.daysRemaining) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                SummaryHeroCard(
                    activeCount: activeItems.count,
                    expiredCount: expiredItems.count,
                    dueTodayCount: dueTodayItems.count,
                    upcomingCount: upcomingItems.count
                )

                if !dueTodayItems.isEmpty {
                    urgentSection
                }

                categorySection
                recentSection
            }
            .padding(AppTheme.pagePadding)
            .padding(.bottom, 90)
        }
        .background(AppTheme.canvasGradient.ignoresSafeArea())
        .navigationTitle("到期提醒")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
    }

    private var urgentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "今天到期", subtitle: "优先处理这些事项")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dueTodayItems, id: \.id) { item in
                        NavigationLink {
                            ItemDetailView(item: item)
                        } label: {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .top) {
                                    Label("今天到期", systemImage: "clock.badge.exclamationmark.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(.white.opacity(0.16), in: Capsule(style: .continuous))

                                    Spacer(minLength: 10)

                                    Image(systemName: item.category.symbolName)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white.opacity(0.92))
                                        .frame(width: 40, height: 40)
                                        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    CategoryBadge(category: item.category, emphasis: true)
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .lineLimit(2)
                                }

                                HStack(spacing: 8) {
                                    homePill(text: item.reminderEnabled ? "提醒已开" : "未提醒", icon: item.reminderEnabled ? "bell.badge.fill" : "bell.slash")
                                    homePill(text: item.expireDate.formatted(AppFormatters.shortDate), icon: "calendar")
                                }
                            }
                            .padding(18)
                            .frame(width: 220, alignment: .leading)
                            .background(urgentCardGradient(for: item), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(.white.opacity(0.12))
                            }
                            .shadow(color: Color.orange.opacity(0.2), radius: 14, x: 0, y: 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "快捷分类", subtitle: "按场景快速查看")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ExpiryCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                        selectedTab = .items
                    } label: {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack {
                                Image(systemName: category.symbolName)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.95))
                                    .frame(width: 40, height: 40)
                                    .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                Spacer()
                                Label("\(countForCategory(category)) 项", systemImage: "tray.full")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.92))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(.white.opacity(0.14), in: Capsule(style: .continuous))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.title)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text(categoryDescription(category))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.82))
                                Text(categoryRiskSummary(category))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.95))
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
                        .background(categoryCardGradient(category), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(.white.opacity(0.12))
                        }
                        .shadow(color: category.tint.opacity(0.18), radius: 14, x: 0, y: 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                sectionHeader(title: "最近 7 天", subtitle: "从紧急到宽松排序")
                Spacer()
                Button("查看全部") {
                    selectedTab = .items
                }
                .font(.subheadline.weight(.semibold))
            }

            if upcomingItems.isEmpty {
                EmptyStateView(
                    title: "最近没有紧急事项",
                    message: "现在可以先安心，新的到期提醒随时可以补充进来。",
                    systemImage: "party.popper",
                    actionTitle: "添加事项",
                    action: onAddTap
                )
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(upcomingItems.prefix(4), id: \.id) { item in
                        NavigationLink {
                            ItemDetailView(item: item)
                        } label: {
                            ItemCardView(item: item, style: .prominent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var bottomActionBar: some View {
        Button(action: onAddTap) {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                Text("新增到期事项")
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.accentGradient, in: Capsule(style: .continuous))
            .shadow(color: Color.accentColor.opacity(0.28), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppTheme.pagePadding)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func categoryDescription(_ category: ExpiryCategory) -> String {
        switch category {
        case .subscription:
            return "会员与自动续费"
        case .document:
            return "证件与有效期"
        case .warranty:
            return "保修与售后节点"
        case .foodMedicine:
            return "保质期与药品管理"
        }
    }

    private func countForCategory(_ category: ExpiryCategory) -> Int {
        activeItems.filter { $0.category == category }.count
    }

    private func expiredCountForCategory(_ category: ExpiryCategory) -> Int {
        activeItems.filter { $0.category == category && $0.isExpired }.count
    }

    private func dueTodayCountForCategory(_ category: ExpiryCategory) -> Int {
        activeItems.filter { $0.category == category && $0.isDueToday }.count
    }

    private func categoryRiskSummary(_ category: ExpiryCategory) -> String {
        let expiredCount = expiredCountForCategory(category)
        let dueTodayCount = dueTodayCountForCategory(category)

        if expiredCount > 0 {
            return "已过期 \(expiredCount) 项"
        }
        if dueTodayCount > 0 {
            return "今天到期 \(dueTodayCount) 项"
        }
        return countForCategory(category) > 0 ? "近期可集中查看" : "当前暂无事项"
    }

    private func categoryCardGradient(_ category: ExpiryCategory) -> LinearGradient {
        if expiredCountForCategory(category) > 0 {
            return LinearGradient(
                colors: [Color.red.opacity(0.92), category.tint.opacity(0.82), Color.orange.opacity(0.58)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if dueTodayCountForCategory(category) > 0 {
            return LinearGradient(
                colors: [Color.orange.opacity(0.92), category.tint.opacity(0.8), Color.yellow.opacity(0.56)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [category.tint.opacity(0.94), category.tint.opacity(0.74), Color.white.opacity(0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func urgentCardGradient(for item: ExpiryItem) -> LinearGradient {
        LinearGradient(
            colors: [Color.orange.opacity(0.96), item.category.tint.opacity(0.84), Color.yellow.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func homePill(text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.94))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.14), in: Capsule(style: .continuous))
    }
}
