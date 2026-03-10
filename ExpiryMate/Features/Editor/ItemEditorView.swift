import SwiftUI
import SwiftData

struct ItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isTitleFocused: Bool

    private let item: ExpiryItem?

    @State private var title: String
    @State private var category: ExpiryCategory
    @State private var expireDate: Date
    @State private var reminderEnabled: Bool
    @State private var selectedPresets: Set<ReminderPreset>
    @State private var note: String
    @State private var isSaving = false

    init(item: ExpiryItem? = nil) {
        self.item = item
        _title = State(initialValue: item?.title ?? "")
        _category = State(initialValue: item?.category ?? .document)
        _expireDate = State(initialValue: item?.expireDate ?? Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now)
        _reminderEnabled = State(initialValue: item?.reminderEnabled ?? true)
        _selectedPresets = State(initialValue: Set(item?.reminderPresets ?? [.sameDay, .oneDayBefore]))
        _note = State(initialValue: item?.note ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                previewCard
                basicSection
                categorySection
                reminderSection
                noteSection
            }
            .padding(AppTheme.pagePadding)
            .padding(.bottom, 28)
        }
        .background(AppTheme.canvasGradient.ignoresSafeArea())
        .navigationTitle(item == nil ? "新增事项" : "编辑事项")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(isSaving ? "保存中" : "保存") {
                    Task { await save() }
                }
                .fontWeight(.semibold)
                .disabled(isSaving || normalizedTitle.isEmpty || (reminderEnabled && selectedPresets.isEmpty))
            }
        }
        .onAppear {
            isTitleFocused = item == nil
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            CategoryBadge(category: category, emphasis: true)

            Text(normalizedTitle.isEmpty ? "给这个事项起个名字" : normalizedTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(normalizedTitle.isEmpty ? .secondary : .primary)

            HStack(spacing: 12) {
                Label(expireDate.formatted(AppFormatters.fullDate), systemImage: "calendar")
                Spacer()
                Text(countdownText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(countdownColor)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(22)
        .appCard(radius: 30)
    }

    private var basicSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "基础信息", subtitle: "先描述这是一个什么提醒")

            VStack(alignment: .leading, spacing: 10) {
                Text("事项名称")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                TextField("例如：驾照换证、视频会员续费", text: $title)
                    .focused($isTitleFocused)
                    .textInputAutocapitalization(.never)
                    .padding(16)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                DatePicker("到期日期", selection: $expireDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(16)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(18)
        .appCard()
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "分类", subtitle: "颜色和图标会跟随分类变化")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ExpiryCategory.allCases) { value in
                    Button {
                        category = value
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: value.symbolName)
                                .font(.subheadline.weight(.bold))
                                .frame(width: 34, height: 34)
                                .background(value.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Text(value.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                        .foregroundStyle(category == value ? value.tint : .primary)
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(
                            (category == value ? value.tint.opacity(0.10) : Color.primary.opacity(0.04)),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .appCard()
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "提醒", subtitle: "默认会在上午 9 点通知你")

            Toggle(isOn: $reminderEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("开启提醒")
                        .font(.headline)
                    Text(reminderEnabled ? "已为这个事项启用通知" : "只保留记录，不发送通知")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            if reminderEnabled {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(ReminderPreset.allCases) { preset in
                        let isSelected = selectedPresets.contains(preset)

                        Button {
                            if isSelected {
                                selectedPresets.remove(preset)
                            } else {
                                selectedPresets.insert(preset)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text("通知一次")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(
                                isSelected ? Color.accentColor.opacity(0.10) : Color.primary.opacity(0.04),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .appCard()
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "备注", subtitle: "补充一些你未来会需要的信息")

            TextField("例如：自动续费前记得取消，或准备哪些材料", text: $note, axis: .vertical)
                .lineLimit(5, reservesSpace: true)
                .padding(16)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(18)
        .appCard()
    }

    private var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var countdownText: String {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.startOfDay(for: expireDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return AppFormatters.countdownText(daysRemaining: days)
    }

    private var countdownColor: Color {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.startOfDay(for: expireDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        if days < 0 { return .red }
        if days == 0 { return .orange }
        if days <= 7 { return category.tint }
        return .secondary
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @MainActor
    private func save() async {
        guard !normalizedTitle.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }

        let reminderPresets = selectedPresets.sorted { $0.daysBefore < $1.daysBefore }
        let target = item ?? ExpiryItem(title: normalizedTitle, category: category, expireDate: expireDate)

        target.title = normalizedTitle
        target.category = category
        target.expireDate = expireDate
        target.reminderEnabled = reminderEnabled
        target.reminderPresets = reminderEnabled ? reminderPresets : []
        target.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        target.refreshUpdatedAt()

        if item == nil {
            modelContext.insert(target)
        }

        try? modelContext.save()
        await NotificationScheduler.shared.sync(for: target)
        WidgetSyncService.sync(using: modelContext)
        dismiss()
    }
}
