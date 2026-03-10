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
                .init(id: UUID(), title: "视频会员续费", categoryRawValue: "subscription", expireDate: .now, daysRemaining: 3),
                .init(id: UUID(), title: "驾照换证", categoryRawValue: "document", expireDate: .now, daysRemaining: 12)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近到期")
                    .font(.headline)
                Spacer()
                Text(entry.date.formatted(.dateTime.month().day()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if entry.snapshot.items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("还没有事项")
                        .font(.subheadline.weight(.semibold))
                    Text("打开 App 添加订阅、证件或保修提醒。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(displayItems) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(item.daysRemaining >= 0 ? "剩余 \(item.daysRemaining) 天" : "已过期 \(abs(item.daysRemaining)) 天")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .padding()
    }

    private var displayItems: ArraySlice<WidgetSnapshot.SnapshotItem> {
        let limit = family == .systemSmall ? 2 : 3
        return entry.snapshot.items.prefix(limit)
    }
}
