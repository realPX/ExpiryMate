import Foundation
import SwiftData
import WidgetKit

enum WidgetSyncService {
    static func sync(using context: ModelContext) {
        let descriptor = FetchDescriptor<ExpiryItem>(sortBy: [SortDescriptor(\ExpiryItem.expireDate)])
        let items = ((try? context.fetch(descriptor)) ?? [])
            .filter { !$0.isArchived }
            .sorted { $0.expireDate < $1.expireDate }
            .prefix(3)
            .map {
                WidgetSnapshot.SnapshotItem(
                    id: $0.id,
                    title: $0.title,
                    categoryRawValue: $0.category.rawValue,
                    expireDate: $0.expireDate,
                    daysRemaining: $0.daysRemaining
                )
            }

        let snapshot = WidgetSnapshot(generatedAt: .now, items: Array(items))
        try? WidgetSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
