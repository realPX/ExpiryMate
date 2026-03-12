import SwiftUI
import SwiftData

struct ItemEditorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isTitleFocused: Bool
    @AppStorage(AppConstants.defaultReminderHourKey, store: AppConstants.sharedDefaults)
    private var defaultReminderHour = AppConstants.defaultReminderHour
    @AppStorage(AppConstants.defaultReminderMinuteKey, store: AppConstants.sharedDefaults)
    private var defaultReminderMinute = AppConstants.defaultReminderMinute

    private let item: ExpiryItem?

    @State private var title: String
    @State private var category: ExpiryCategory
    @State private var customCategoryName: String
    @State private var expireDate: Date
    @State private var reminderEnabled: Bool
    @State private var selectedPresets: Set<ReminderPreset>
    @State private var note: String
    @State private var isSaving = false

    init(item: ExpiryItem? = nil) {
        self.item = item
        _title = State(initialValue: item?.title ?? "")
        _category = State(initialValue: item?.category ?? .document)
        _customCategoryName = State(initialValue: item?.normalizedCustomCategoryName ?? "")
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
        .tint(AppTheme.warmSage)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                }
                label: {
                    Text("取消")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.warmStone)
                        .appToolbarCapsule(tint: AppTheme.warmStone)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await save() }
                }
                label: {
                    Text(isSaving ? "保存中" : "保存")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .appToolbarCapsule(prominent: true, tint: AppTheme.warmSage)
                }
                .disabled(
                    isSaving
                    || normalizedTitle.isEmpty
                    || (category == .custom && normalizedCustomCategoryName == nil)
                    || (reminderEnabled && selectedPresets.isEmpty)
                )
                .opacity(
                    isSaving
                    || normalizedTitle.isEmpty
                    || (category == .custom && normalizedCustomCategoryName == nil)
                    || (reminderEnabled && selectedPresets.isEmpty)
                    ? 0.62 : 1
                )
            }
        }
        .onAppear {
            isTitleFocused = item == nil
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(item == nil ? "新建预览" : "编辑预览", systemImage: item == nil ? "sparkles" : "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(previewAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(previewAccent.opacity(colorScheme == .dark ? 0.18 : 0.12), in: Capsule(style: .continuous))

                    CategoryBadge(
                        category: category,
                        titleOverride: editorCategoryTitle,
                        emphasis: true,
                        maxWidth: CategoryBadge.WidthStyle.editor.value
                    )
                }

                Spacer(minLength: 12)

                Image(systemName: category.symbolName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(previewAccent)
                    .frame(width: 48, height: 48)
                    .background(previewAccent.opacity(colorScheme == .dark ? 0.18 : 0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(previewAccent.opacity(colorScheme == .dark ? 0.20 : 0.12))
                    }
            }

            Text(normalizedTitle.isEmpty ? "给这个事项起个名字" : normalizedTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(normalizedTitle.isEmpty ? .secondary : .primary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                editorPill(
                    text: expireDate.formatted(AppFormatters.fullDate),
                    icon: "calendar",
                    tint: previewAccent
                )
                editorPill(
                    text: reminderPreviewText,
                    icon: reminderEnabled ? "bell.badge.fill" : "bell.slash",
                    tint: reminderEnabled ? category.tint : .secondary
                )
            }

            HStack(spacing: 12) {
                Text("当前进度")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(previewAccent)

                Spacer()

                Text(countdownText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(countdownColor)
            }
        }
        .padding(22)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(previewAccent.opacity(colorScheme == .dark ? 0.22 : 0.14))
                .frame(width: 92, height: 34)
                .blur(radius: 18)
                .offset(x: 20, y: -8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(AppTheme.stroke)
        }
        .shadow(color: AppTheme.shadow, radius: 16, x: 0, y: 8)
    }

    private var basicSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "基础信息",
                subtitle: "先描述这是一个什么提醒",
                icon: "square.and.pencil",
                accent: AppTheme.warmStone
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("事项名称")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                fieldCard(tint: AppTheme.warmStone) {
                    TextField("例如：驾照换证、视频会员续费", text: $title)
                        .focused($isTitleFocused)
                        .textInputAutocapitalization(.never)
                }

                fieldCard(tint: previewAccent) {
                    DatePicker("到期日期", selection: $expireDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
            }
        }
        .padding(18)
        .sectionCard(accent: AppTheme.warmStone)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "分类",
                subtitle: "可以使用固定分类，也可以输入自定义分类名称",
                icon: "square.grid.2x2.fill",
                accent: category.tint
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ExpiryCategory.allCases) { value in
                    Button {
                        category = value
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: value.symbolName)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(category == value ? value.tint : .primary)
                                .frame(width: 34, height: 34)
                                .background(value.tint.opacity(colorScheme == .dark ? 0.18 : 0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(value.tint.opacity(colorScheme == .dark ? 0.18 : 0.12))
                                }
                            Text(value.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                        .foregroundStyle(category == value ? value.tint : .primary)
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(
                            (category == value ? value.tint.opacity(colorScheme == .dark ? 0.16 : 0.10) : AppTheme.controlFill),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(category == value ? value.tint.opacity(0.18) : AppTheme.stroke)
                        }
                    }
                    .buttonStyle(.appPressable)
                }
            }

            if category == .custom {
                VStack(alignment: .leading, spacing: 10) {
                    Text("自定义分类名称")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    fieldCard(tint: category.tint) {
                        TextField("例如：宠物、旅行、考试", text: $customCategoryName)
                            .textInputAutocapitalization(.never)
                    }

                    hintCard(
                        title: "显示说明",
                        message: "保存后会在列表、详情和通知中显示这个分类名称。",
                        accent: category.tint
                    )
                }
            }
        }
        .padding(18)
        .sectionCard(accent: category.tint)
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "提醒",
                subtitle: "默认会在 \(observedReminderTimeText) 通知你",
                icon: "bell.badge.fill",
                accent: reminderSectionAccent
            )

            HStack(spacing: 14) {
                Image(systemName: reminderEnabled ? "bell.badge.fill" : "bell.slash")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(reminderSectionAccent)
                            .frame(width: 40, height: 40)
                            .background(reminderSectionAccent.opacity(colorScheme == .dark ? 0.18 : 0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(reminderSectionAccent.opacity(colorScheme == .dark ? 0.20 : 0.12))
                    }

                Toggle(isOn: $reminderEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("开启提醒")
                            .font(.headline.weight(.semibold))
                        Text(reminderEnabled ? "已为这个事项启用通知" : "只保留记录，不发送通知")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .background(AppTheme.controlStrongFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(AppTheme.stroke)
            }

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
                                    .foregroundStyle(isSelected ? reminderSectionAccent : .secondary)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(
                                isSelected ? reminderSectionAccent.opacity(colorScheme == .dark ? 0.16 : 0.10) : AppTheme.controlFill,
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(isSelected ? reminderSectionAccent.opacity(0.18) : AppTheme.stroke)
                            }
                        }
                        .buttonStyle(.appPressable)
                    }
                }
            }
        }
        .padding(18)
        .sectionCard(accent: reminderSectionAccent)
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "备注",
                subtitle: "补充一些你未来会需要的信息",
                icon: "text.alignleft",
                accent: AppTheme.warmStone
            )

            fieldCard(tint: AppTheme.warmStone) {
                TextField("例如：自动续费前记得取消，或准备哪些材料", text: $note, axis: .vertical)
                    .lineLimit(5, reservesSpace: true)
            }
        }
        .padding(18)
        .sectionCard(accent: AppTheme.warmStone)
    }

    private var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedCustomCategoryName: String? {
        let trimmed = customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var editorCategoryTitle: String {
        if category == .custom {
            return normalizedCustomCategoryName ?? "自定义"
        }
        return category.title
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
        if days < 0 { return AppTheme.softDanger }
        if days == 0 { return AppTheme.softWarning }
        if days <= 7 { return category.tint }
        return .secondary
    }

    private var previewAccent: Color {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.startOfDay(for: expireDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        if days < 0 { return AppTheme.softDanger }
        if days == 0 { return AppTheme.softWarning }
        if days <= 7 { return category.tint }
        return category.tint
    }

    private var reminderSectionAccent: Color {
        reminderEnabled ? category.tint : .secondary
    }

    private var reminderPreviewText: String {
        if !reminderEnabled {
            return "未开启提醒"
        }

        if selectedPresets.isEmpty {
            return "\(observedReminderTimeText) · 待选择"
        }

        return "\(observedReminderTimeText) · \(selectedPresets.count) 个提醒"
    }

    private var observedReminderTimeText: String {
        AppFormatters.reminderTimeText(
            hour: defaultReminderHour,
            minute: defaultReminderMinute
        )
    }

    private func sectionHeader(title: String, subtitle: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(AppTheme.controlStrongFill, in: Capsule(style: .continuous))
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(accent.opacity(colorScheme == .dark ? 0.16 : 0.12))
                }

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func editorPill(text: String, icon: String, tint: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tint.opacity(colorScheme == .dark ? 0.16 : 0.10), in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(tint.opacity(colorScheme == .dark ? 0.16 : 0.10))
            }
    }

    private func fieldCard<Content: View>(
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(16)
            .background(AppTheme.controlStrongFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(tint.opacity(colorScheme == .dark ? 0.18 : 0.12))
            }
    }

    private func hintCard(title: String, message: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .padding(14)
        .background(AppTheme.controlFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppTheme.stroke)
        }
        .appAccentGlow(accent, width: 62, height: 62, opacity: 0.08, x: 8, y: -10, blur: 16)
    }

    @MainActor
    private func save() async {
        guard !normalizedTitle.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }

        let reminderPresets = selectedPresets.sorted { $0.daysBefore < $1.daysBefore }
        let target = item ?? ExpiryItem(
            title: normalizedTitle,
            category: category,
            customCategoryName: normalizedCustomCategoryName,
            expireDate: expireDate
        )

        target.title = normalizedTitle
        target.category = category
        target.customCategoryName = category == .custom ? normalizedCustomCategoryName : nil
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

private extension View {
    func sectionCard(accent: Color) -> some View {
        background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .strokeBorder(AppTheme.stroke)
            }
            .shadow(color: AppTheme.shadow, radius: 16, x: 0, y: 8)
            .appAccentGlow(accent, width: 82, height: 82, opacity: 0.09, x: 12, y: -16, blur: 20)
    }
}
