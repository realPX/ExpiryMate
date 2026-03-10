import SwiftUI
import SwiftData

struct CustomSortSheet: View {
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
                    ForEach(draftItems, id: \.id) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.category.symbolName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(item.category.tint)
                                .frame(width: 34, height: 34)
                                .background(item.category.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                Text(item.category.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove(perform: moveItems)
                } footer: {
                    Text("按住右侧拖拽手柄即可调整顺序，保存后会作为自定义排序结果。")
                }
            }
            .environment(\.editMode, .constant(.active))
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

    private func moveItems(from source: IndexSet, to destination: Int) {
        draftItems.move(fromOffsets: source, toOffset: destination)
    }

    @MainActor
    private func save() async {
        await ItemMaintenanceService.shared.applyCustomOrder(draftItems, using: modelContext)
        dismiss()
    }
}
