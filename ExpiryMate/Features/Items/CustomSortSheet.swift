import SwiftUI
import SwiftData

struct CustomSortSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let items: [ExpiryItem]

    @State private var draftItems: [ExpiryItem]

    init(items: [ExpiryItem]) {
        self.items = items
        _draftItems = State(initialValue: items)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    introCard
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }

                Section {
                    ForEach(draftItems, id: \.id) { item in
                        sortRow(for: item)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .onMove(perform: moveItems)
                } footer: {
                    Text("按住右侧拖拽手柄即可调整顺序，保存后会作为自定义排序结果。")
                }
            }
            .environment(\.editMode, .constant(.active))
            .scrollContentBackground(.hidden)
            .background(AppTheme.canvasGradient.ignoresSafeArea())
            .listStyle(.plain)
            .navigationTitle("自定义排序")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("拖拽排序", systemImage: "line.3.horizontal.decrease.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.warmSage)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(AppTheme.controlStrongFill, in: Capsule(style: .continuous))
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(AppTheme.warmSage.opacity(colorScheme == .dark ? 0.18 : 0.12))
                        }

                    Text("调整事项展示顺序")
                        .font(.headline.weight(.semibold))
                    Text("这里的顺序会用于列表里的自定义排序结果。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Image(systemName: "arrow.up.arrow.down")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.warmSage)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.controlStrongFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppTheme.warmSage.opacity(colorScheme == .dark ? 0.20 : 0.12))
                    }
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(AppTheme.stroke)
        }
        .shadow(color: AppTheme.shadow, radius: 16, x: 0, y: 8)
        .appAccentGlow(AppTheme.warmSand, width: 84, height: 84, opacity: 0.10, x: 12, y: -16, blur: 20)
    }

    private func sortRow(for item: ExpiryItem) -> some View {
        HStack(spacing: 14) {
            Image(systemName: item.category.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(item.category.tint)
                .frame(width: 40, height: 40)
                .background(item.category.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(item.category.tint.opacity(0.12))
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(item.displayCategoryTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(item.category.tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(item.category.tint.opacity(0.10), in: Capsule(style: .continuous))

                    Text(item.expireDate.formatted(AppFormatters.shortDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(AppFormatters.countdownText(daysRemaining: item.daysRemaining))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor(for: item))
                Image(systemName: "line.3.horizontal")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppTheme.stroke)
        }
        .shadow(color: AppTheme.shadow, radius: 16, x: 0, y: 8)
        .appAccentGlow(statusColor(for: item), width: 70, height: 70, opacity: 0.09, x: 10, y: -12, blur: 18)
    }

    private func statusColor(for item: ExpiryItem) -> Color {
        if item.isArchived { return .secondary }
        if item.isExpired { return AppTheme.softDanger }
        if item.isDueToday { return AppTheme.softWarning }
        if item.isUpcoming { return item.category.tint }
        return .secondary
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        draftItems.move(fromOffsets: source, toOffset: destination)
    }

    @MainActor
    private func save() async {
        await ItemMaintenanceService.shared.applyCustomOrder(draftItems, using: modelContext)
        dismiss()
    }
}
