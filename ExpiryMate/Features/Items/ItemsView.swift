import SwiftUI
import SwiftData

struct ItemsView: View {
    private struct ItemSectionData: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let items: [ExpiryItem]
    }

    private enum BatchAction {
        case archiveExpired
        case restoreArchived
        case deleteArchived
    }

    @Environment(\.modelContext) private var modelContext
    @Binding var selectedCategory: ExpiryCategory?
    let onAddTap: () -> Void

    @Query(sort: [SortDescriptor(\ExpiryItem.expireDate), SortDescriptor(\ExpiryItem.createdAt, order: .reverse)])
    private var items: [ExpiryItem]

    @AppStorage("showArchivedItems") private var showArchivedItems = true
    @AppStorage("autoArchiveExpiredItems") private var autoArchiveExpiredItems = false
    @AppStorage("groupExpiredItemsSeparately") private var groupExpiredItemsSeparately = true
    @AppStorage("itemSortMode") private var itemSortModeRawValue = ItemSortMode.dueDateAscending.rawValue

    @State private var searchText = ""
    @State private var filter: ItemFilter = .all
    @State private var pendingBatchAction: BatchAction?
    @State private var pendingSingleDeleteItem: ExpiryItem?
    @State private var isPerformingBatchAction = false
    @State private var isSelectionMode = false
    @State private var selectedItemIDs = Set<UUID>()
    @State private var isShowingCustomSortSheet = false
    @State private var editingItem: ExpiryItem?

    init(
        selectedCategory: Binding<ExpiryCategory?>,
        onAddTap: @escaping () -> Void
    ) {
        _selectedCategory = selectedCategory
        self.onAddTap = onAddTap
    }

    private var searchedItems: [ExpiryItem] {
        sort(items.filter { item in
            let matchesSearch = searchText.isEmpty
                || item.title.localizedCaseInsensitiveContains(searchText)
                || item.note.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory.map { item.category == $0 } ?? true
            return matchesSearch && matchesCategory
        })
    }

    private var activeItems: [ExpiryItem] {
        searchedItems.filter { !$0.isArchived }
    }

    private var expiredItems: [ExpiryItem] {
        activeItems.filter(\.isExpired)
    }

    private var upcomingItems: [ExpiryItem] {
        activeItems.filter { !$0.isExpired }
    }

    private var archivedItems: [ExpiryItem] {
        searchedItems.filter(\.isArchived)
    }

    private var visibleFilters: [ItemFilter] {
        showArchivedItems
            ? ItemFilter.allCases
            : ItemFilter.allCases.filter { $0 != .archived }
    }

    private var allExpiredItems: [ExpiryItem] {
        items.filter { !$0.isArchived && $0.isExpired }
    }

    private var allArchivedItems: [ExpiryItem] {
        items.filter(\.isArchived)
    }

    private var displayedSections: [ItemSectionData] {
        switch filter {
        case .all:
            if groupExpiredItemsSeparately {
                return [
                    ItemSectionData(
                        title: "待处理",
                        subtitle: "包含今天到期和未来事项",
                        items: upcomingItems
                    ),
                    ItemSectionData(
                        title: "已过期",
                        subtitle: "建议尽快处理或归档",
                        items: expiredItems
                    ),
                    ItemSectionData(
                        title: "已归档",
                        subtitle: "暂时不在主列表中打扰你",
                        items: showArchivedItems ? archivedItems : []
                    )
                ]
                .filter { !$0.items.isEmpty }
            } else {
                return [
                    ItemSectionData(
                        title: "全部事项",
                        subtitle: "按到期时间排序",
                        items: activeItems
                    ),
                    ItemSectionData(
                        title: "已归档",
                        subtitle: "暂时不在主列表中打扰你",
                        items: showArchivedItems ? archivedItems : []
                    )
                ]
                .filter { !$0.items.isEmpty }
            }

        case .upcoming:
            return [
                ItemSectionData(
                    title: "待处理",
                    subtitle: "优先处理这些事项",
                    items: upcomingItems
                )
            ]

        case .expired:
            return [
                ItemSectionData(
                    title: "已过期",
                    subtitle: "支持批量归档和恢复整理",
                    items: expiredItems
                )
            ]

        case .archived:
            return [
                ItemSectionData(
                    title: "已归档",
                    subtitle: "可以恢复到主列表，或批量清理",
                    items: showArchivedItems ? archivedItems : []
                )
            ]
        }
    }

    private var displayedItems: [ExpiryItem] {
        displayedSections.flatMap(\.items)
    }

    private var itemSortMode: ItemSortMode {
        get { ItemSortMode(rawValue: itemSortModeRawValue) ?? .dueDateAscending }
        set { itemSortModeRawValue = newValue.rawValue }
    }

    private var canCustomizeSort: Bool {
        filter == .all && selectedCategory == nil && searchText.isEmpty && showArchivedItems
    }

    private var selectedItems: [ExpiryItem] {
        items.filter { selectedItemIDs.contains($0.id) }
    }

    private var selectionContainsArchived: Bool {
        selectedItems.contains(where: \.isArchived)
    }

    private var selectionContainsActive: Bool {
        selectedItems.contains(where: { !$0.isArchived })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                filterPanel

                VStack(alignment: .leading, spacing: 14) {
                    headerBar

                    if displayedSections.isEmpty {
                        EmptyStateView(
                            title: emptyStateTitle,
                            message: emptyStateMessage,
                            systemImage: emptyStateSymbol,
                            actionTitle: "新增事项",
                            action: onAddTap
                        )
                    } else {
                        LazyVStack(spacing: 18) {
                            ForEach(displayedSections) { section in
                                VStack(alignment: .leading, spacing: 12) {
                                    sectionHeader(title: section.title, subtitle: section.subtitle, count: section.items.count)

                                    LazyVStack(spacing: 14) {
                                        ForEach(section.items, id: \.id) { item in
                                            itemRow(for: item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(AppTheme.pagePadding)
            .padding(.bottom, isSelectionMode ? 100 : 24)
        }
        .background(AppTheme.canvasGradient.ignoresSafeArea())
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("搜索标题或备注"))
        .navigationTitle("全部事项")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            if isSelectionMode {
                selectionActionBar
            }
        }
        .onChange(of: showArchivedItems) { _, isEnabled in
            if !isEnabled, filter == .archived {
                filter = .all
            }
        }
        .onChange(of: displayedItems.map(\.id)) { _, ids in
            let currentIDs = Set(ids)
            selectedItemIDs = selectedItemIDs.intersection(currentIDs)
            if selectedItemIDs.isEmpty {
                isSelectionMode = false
            }
        }
        .task(id: autoArchiveExpiredItems) {
            guard autoArchiveExpiredItems else { return }
            _ = await ItemMaintenanceService.shared.autoArchiveEligibleItems(using: modelContext)
        }
        .confirmationDialog(
            "清空所有已归档事项？",
            isPresented: Binding(
                get: { pendingBatchAction == .deleteArchived },
                set: { if !$0 { pendingBatchAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除全部归档事项", role: .destructive) {
                Task { await performBatchAction(.deleteArchived) }
            }
            Button("取消", role: .cancel) {
                pendingBatchAction = nil
            }
        } message: {
            Text("这会删除当前所有已归档事项，且无法恢复。")
        }
        .alert(
            "删除这个事项？",
            isPresented: Binding(
                get: { pendingSingleDeleteItem != nil },
                set: { if !$0 { pendingSingleDeleteItem = nil } }
            ),
            presenting: pendingSingleDeleteItem
        ) { item in
            Button("删除", role: .destructive) {
                Task { await delete(item: item) }
            }
            Button("取消", role: .cancel) {
                pendingSingleDeleteItem = nil
            }
        } message: { _ in
            Text("删除后，对应通知也会一并取消。")
        }
        .sheet(isPresented: $isShowingCustomSortSheet) {
            CustomSortSheet(items: displayedItems)
        }
        .sheet(item: $editingItem) { item in
            NavigationStack {
                ItemEditorView(item: item)
            }
        }
    }

    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("筛选与查找")
                    .font(.title3.weight(.bold))
                Text("支持按状态、分类和归档视图管理你的到期事项")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Picker("筛选", selection: $filter) {
                ForEach(visibleFilters) { value in
                    Text(value.title).tag(value)
                }
            }
            .pickerStyle(.segmented)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    filterChip(title: "全部分类", category: nil)
                    ForEach(ExpiryCategory.allCases) { category in
                        filterChip(title: category.title, category: category)
                    }
                }
                .padding(.vertical, 2)
            }

            HStack(spacing: 10) {
                quickStat(title: "已过期", value: "\(allExpiredItems.count)")
                quickStat(title: "已归档", value: "\(allArchivedItems.count)")
                quickStat(title: "筛选结果", value: "\(displayedCount)")
            }
        }
        .padding(18)
        .appCard()
    }

    private var headerBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("事项列表")
                    .font(.title3.weight(.bold))
                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelectionMode {
                HStack(spacing: 10) {
                    Button(displayedItems.count == selectedItemIDs.count ? "取消全选" : "全选") {
                        toggleSelectAll()
                    }
                    .font(.subheadline.weight(.semibold))

                    Button("完成") {
                        exitSelectionMode()
                    }
                    .font(.subheadline.weight(.semibold))
                }
            } else {
                HStack(spacing: 10) {
                    sortMenu

                    if itemSortMode == .custom, canCustomizeSort, !displayedItems.isEmpty {
                        Button {
                            isShowingCustomSortSheet = true
                        } label: {
                            Label("排序", systemImage: "arrow.up.arrow.down")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(AppTheme.surfaceMuted, in: Capsule(style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    batchMenu

                    Button {
                        enterSelectionMode()
                    } label: {
                        Label("选择", systemImage: "checklist")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(AppTheme.surfaceMuted, in: Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: onAddTap) {
                        Label("新增", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(AppTheme.accentGradient, in: Capsule(style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(ItemSortMode.allCases) { mode in
                Button {
                    itemSortModeRawValue = mode.rawValue
                } label: {
                    Label(mode.title, systemImage: mode.symbolName)
                }
            }
        } label: {
            Label(itemSortMode.shortTitle, systemImage: itemSortMode.symbolName)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.surfaceMuted, in: Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var batchMenu: some View {
        Menu {
            Button {
                Task { await performBatchAction(.archiveExpired) }
            } label: {
                Label("归档全部已过期（\(allExpiredItems.count)）", systemImage: "archivebox.fill")
            }
            .disabled(allExpiredItems.isEmpty || isPerformingBatchAction)

            Button {
                Task { await performBatchAction(.restoreArchived) }
            } label: {
                Label("恢复全部归档（\(allArchivedItems.count)）", systemImage: "arrow.uturn.backward.circle.fill")
            }
            .disabled(allArchivedItems.isEmpty || isPerformingBatchAction)

            Button(role: .destructive) {
                pendingBatchAction = .deleteArchived
            } label: {
                Label("清空全部归档（\(allArchivedItems.count)）", systemImage: "trash.fill")
            }
            .disabled(allArchivedItems.isEmpty || isPerformingBatchAction)
        } label: {
            Label("批量操作", systemImage: "ellipsis.circle")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.surfaceMuted, in: Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var selectionActionBar: some View {
        VStack(spacing: 10) {
            HStack {
                Text("已选择 \(selectedItemIDs.count) 项")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if !selectedItemIDs.isEmpty {
                    Button("清空选择") {
                        selectedItemIDs.removeAll()
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }

            HStack(spacing: 12) {
                if selectionContainsActive {
                    selectionButton(title: "归档", systemImage: "archivebox.fill") {
                        Task { await archiveSelectedActiveItems() }
                    }
                }

                if selectionContainsArchived {
                    selectionButton(title: "恢复", systemImage: "arrow.uturn.backward.circle.fill") {
                        Task { await restoreSelectedArchivedItems() }
                    }
                }

                selectionButton(title: "删除", systemImage: "trash.fill", isDestructive: true) {
                    Task { await deleteSelectedItems() }
                }
            }
        }
        .padding(.horizontal, AppTheme.pagePadding)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func itemRow(for item: ExpiryItem) -> some View {
        let row = ItemCardView(item: item, style: .compact)
            .overlay(alignment: .topTrailing) {
                if isSelectionMode {
                    selectionBadge(for: item)
                        .padding(12)
                }
            }
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    if isSelectionMode {
                        toggleSelection(for: item)
                    } else {
                        enterSelectionMode(with: item)
                    }
                } label: {
                    Label(
                        isSelectionMode && selectedItemIDs.contains(item.id) ? "取消选择" : "选择此项",
                        systemImage: isSelectionMode && selectedItemIDs.contains(item.id) ? "minus.circle" : "checkmark.circle"
                    )
                }

                if item.isArchived {
                    Button {
                        Task { await restore(item: item) }
                    } label: {
                        Label("恢复到列表", systemImage: "arrow.uturn.backward.circle")
                    }
                } else {
                    Button {
                        Task { await archive(item: item) }
                    } label: {
                        Label(item.isExpired ? "归档过期事项" : "归档事项", systemImage: "archivebox")
                    }
                }

                if !item.isArchived {
                    Button {
                        editingItem = item
                    } label: {
                        Label("编辑事项", systemImage: "square.and.pencil")
                    }

                    Button {
                        Task { await toggleReminder(for: item) }
                    } label: {
                        Label(
                            item.reminderEnabled ? "关闭提醒" : "开启默认提醒",
                            systemImage: item.reminderEnabled ? "bell.slash" : "bell.badge"
                        )
                    }
                }

                Button(role: .destructive) {
                    pendingSingleDeleteItem = item
                } label: {
                    Label("删除事项", systemImage: "trash")
                }
            } preview: {
                ItemContextPreview(item: item)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: !item.isArchived) {
                Button(role: .destructive) {
                    pendingSingleDeleteItem = item
                } label: {
                    Label("删除", systemImage: "trash")
                }

                if item.isArchived {
                    Button {
                        Task { await restore(item: item) }
                    } label: {
                        Label("恢复", systemImage: "arrow.uturn.backward")
                    }
                    .tint(.blue)
                } else {
                    Button {
                        Task { await archive(item: item) }
                    } label: {
                        Label("归档", systemImage: "archivebox")
                    }
                    .tint(.orange)
                }
            }

        if isSelectionMode {
            Button {
                toggleSelection(for: item)
            } label: {
                row
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                ItemDetailView(item: item)
            } label: {
                row
            }
            .buttonStyle(.plain)
        }
    }

    private func selectionBadge(for item: ExpiryItem) -> some View {
        Image(systemName: selectedItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
            .font(.title3.weight(.bold))
            .foregroundStyle(selectedItemIDs.contains(item.id) ? Color.accentColor : .secondary)
            .padding(6)
            .background(.thinMaterial, in: Circle())
    }

    private var summaryText: String {
        let categoryText = selectedCategory?.title ?? "全部分类"
        if isSelectionMode {
            return "多选模式已开启，可直接点选事项进行归档、恢复或删除"
        }
        if itemSortMode == .custom && !canCustomizeSort {
            return "当前为「\(filter.title) / \(categoryText) / \(itemSortMode.shortTitle)」，切回全部视图可拖拽排序"
        }
        return "当前为「\(filter.title) / \(categoryText) / \(itemSortMode.shortTitle)」，共 \(displayedCount) 项"
    }

    private var displayedCount: Int {
        displayedSections.reduce(0) { $0 + $1.items.count }
    }

    private var emptyStateTitle: String {
        switch filter {
        case .all:
            return "还没有事项"
        case .upcoming:
            return "没有待处理事项"
        case .expired:
            return "没有已过期事项"
        case .archived:
            return "没有归档事项"
        }
    }

    private var emptyStateMessage: String {
        switch filter {
        case .all:
            return "试试先新增一个到期提醒，或者换个筛选条件看看。"
        case .upcoming:
            return "近期没有需要优先处理的事项。"
        case .expired:
            return "目前没有待归档的过期事项。"
        case .archived:
            return showArchivedItems ? "归档区目前是空的。" : "你已在设置中关闭归档显示。"
        }
    }

    private var emptyStateSymbol: String {
        switch filter {
        case .all:
            return "tray"
        case .upcoming:
            return "checkmark.circle"
        case .expired:
            return "clock.badge.exclamationmark"
        case .archived:
            return "archivebox"
        }
    }

    private func filterChip(title: String, category: ExpiryCategory?) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            selectedCategory = category
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isSelected ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(Color.primary.opacity(0.05)),
                    in: Capsule(style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(title: String, subtitle: String, count: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(count) 项")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.surfaceMuted, in: Capsule(style: .continuous))
        }
    }

    private func quickStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func selectionButton(
        title: String,
        systemImage: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    isDestructive ? AnyShapeStyle(Color.red.opacity(0.14)) : AnyShapeStyle(AppTheme.surfaceMuted),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .foregroundStyle(isDestructive ? Color.red : Color.primary)
        }
        .buttonStyle(.plain)
        .disabled(selectedItemIDs.isEmpty)
    }

    private func enterSelectionMode() {
        isSelectionMode = true
        selectedItemIDs.removeAll()
    }

    private func enterSelectionMode(with item: ExpiryItem) {
        isSelectionMode = true
        selectedItemIDs = [item.id]
    }

    private func exitSelectionMode() {
        isSelectionMode = false
        selectedItemIDs.removeAll()
    }

    private func toggleSelection(for item: ExpiryItem) {
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    private func toggleSelectAll() {
        let ids = Set(displayedItems.map(\.id))
        if !ids.isEmpty, ids == selectedItemIDs {
            selectedItemIDs.removeAll()
        } else {
            selectedItemIDs = ids
        }
    }

    private func sort(_ items: [ExpiryItem]) -> [ExpiryItem] {
        switch itemSortMode {
        case .dueDateAscending:
            return items.sorted {
                if $0.expireDate == $1.expireDate {
                    return $0.customOrder < $1.customOrder
                }
                return $0.expireDate < $1.expireDate
            }
        case .dueDateDescending:
            return items.sorted {
                if $0.expireDate == $1.expireDate {
                    return $0.customOrder < $1.customOrder
                }
                return $0.expireDate > $1.expireDate
            }
        case .recentlyUpdated:
            return items.sorted {
                if $0.updatedAt == $1.updatedAt {
                    return $0.customOrder < $1.customOrder
                }
                return $0.updatedAt > $1.updatedAt
            }
        case .custom:
            return items.sorted {
                if $0.customOrder == $1.customOrder {
                    return $0.expireDate < $1.expireDate
                }
                return $0.customOrder < $1.customOrder
            }
        }
    }

    @MainActor
    private func performBatchAction(_ action: BatchAction) async {
        isPerformingBatchAction = true
        defer {
            isPerformingBatchAction = false
            pendingBatchAction = nil
        }

        switch action {
        case .archiveExpired:
            await ItemMaintenanceService.shared.archive(items: allExpiredItems, using: modelContext)
        case .restoreArchived:
            await ItemMaintenanceService.shared.restore(items: allArchivedItems, using: modelContext)
        case .deleteArchived:
            await ItemMaintenanceService.shared.delete(items: allArchivedItems, using: modelContext)
        }
    }

    @MainActor
    private func archive(item: ExpiryItem) async {
        await ItemMaintenanceService.shared.archive(items: [item], using: modelContext)
    }

    @MainActor
    private func restore(item: ExpiryItem) async {
        await ItemMaintenanceService.shared.restore(items: [item], using: modelContext)
    }

    @MainActor
    private func delete(item: ExpiryItem) async {
        await ItemMaintenanceService.shared.delete(items: [item], using: modelContext)
        pendingSingleDeleteItem = nil
        selectedItemIDs.remove(item.id)
    }

    @MainActor
    private func toggleReminder(for item: ExpiryItem) async {
        item.reminderEnabled.toggle()
        if item.reminderEnabled, item.reminderPresets.isEmpty {
            item.reminderPresets = [.sameDay, .oneDayBefore]
        }
        item.refreshUpdatedAt()

        try? modelContext.save()

        if item.reminderEnabled {
            await NotificationScheduler.shared.sync(for: item)
        } else {
            NotificationScheduler.shared.cancel(for: item)
            WidgetSyncService.sync(using: modelContext)
        }
    }

    @MainActor
    private func archiveSelectedActiveItems() async {
        let activeSelection = selectedItems.filter { !$0.isArchived }
        await ItemMaintenanceService.shared.archive(items: activeSelection, using: modelContext)
        exitSelectionMode()
    }

    @MainActor
    private func restoreSelectedArchivedItems() async {
        let archivedSelection = selectedItems.filter(\.isArchived)
        await ItemMaintenanceService.shared.restore(items: archivedSelection, using: modelContext)
        exitSelectionMode()
    }

    @MainActor
    private func deleteSelectedItems() async {
        await ItemMaintenanceService.shared.delete(items: selectedItems, using: modelContext)
        exitSelectionMode()
    }
}
