import Foundation
import SwiftData

@MainActor
final class ItemMaintenanceService {
    static let shared = ItemMaintenanceService()

    private init() {}

    func ensureCustomOrder(using context: ModelContext) {
        let descriptor = FetchDescriptor<ExpiryItem>(sortBy: [
            SortDescriptor(\ExpiryItem.customOrder),
            SortDescriptor(\ExpiryItem.createdAt)
        ])
        let items = (try? context.fetch(descriptor)) ?? []
        guard !items.isEmpty else { return }

        let existingOrders = items.map(\.customOrder)
        let hasDuplicateOrder = Set(existingOrders).count != existingOrders.count
        let allZero = Set(existingOrders) == [0]

        guard hasDuplicateOrder || allZero else { return }

        for (index, item) in items.enumerated() {
            item.customOrder = index
            item.refreshUpdatedAt()
        }

        try? context.save()
    }

    func autoArchiveEligibleItems(using context: ModelContext, threshold: Int = 30) async -> Int {
        let descriptor = FetchDescriptor<ExpiryItem>(sortBy: [SortDescriptor(\ExpiryItem.expireDate)])
        let items = (try? context.fetch(descriptor)) ?? []
        let eligibleItems = items.filter { !$0.isArchived && $0.daysRemaining <= -threshold }

        guard !eligibleItems.isEmpty else { return 0 }

        await archive(items: eligibleItems, using: context)
        return eligibleItems.count
    }

    func archive(items: [ExpiryItem], using context: ModelContext) async {
        guard !items.isEmpty else { return }

        for item in items {
            item.isArchived = true
            item.refreshUpdatedAt()
            NotificationScheduler.shared.cancel(for: item)
        }

        try? context.save()
        WidgetSyncService.sync(using: context)
    }

    func restore(items: [ExpiryItem], using context: ModelContext) async {
        guard !items.isEmpty else { return }

        for item in items {
            item.isArchived = false
            item.refreshUpdatedAt()
        }

        try? context.save()

        for item in items where !item.isExpired {
            await NotificationScheduler.shared.sync(for: item)
        }

        WidgetSyncService.sync(using: context)
    }

    func delete(items: [ExpiryItem], using context: ModelContext) async {
        guard !items.isEmpty else { return }

        for item in items {
            NotificationScheduler.shared.cancel(for: item)
            context.delete(item)
        }

        try? context.save()
        WidgetSyncService.sync(using: context)
    }

    func applyCustomOrder(_ orderedItems: [ExpiryItem], using context: ModelContext) async {
        guard !orderedItems.isEmpty else { return }

        for (index, item) in orderedItems.enumerated() {
            item.customOrder = index
            item.refreshUpdatedAt()
        }

        try? context.save()
        WidgetSyncService.sync(using: context)
    }
}
