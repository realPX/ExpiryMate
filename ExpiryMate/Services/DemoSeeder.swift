import Foundation
import SwiftData

enum DemoSeeder {
    static func seedIfNeeded(using context: ModelContext) {
        var descriptor = FetchDescriptor<ExpiryItem>()
        descriptor.fetchLimit = 1

        let hasExistingItems = ((try? context.fetch(descriptor)) ?? []).isEmpty == false
        guard !hasExistingItems else { return }

        let calendar = Calendar.current
        let sampleItems = [
            ExpiryItem(
                title: "驾照换证",
                category: .document,
                expireDate: calendar.date(byAdding: .day, value: 12, to: .now) ?? .now,
                customOrder: 0,
                note: "记得提前准备体检材料。"
            ),
            ExpiryItem(
                title: "视频会员续费",
                category: .subscription,
                expireDate: calendar.date(byAdding: .day, value: 3, to: .now) ?? .now,
                customOrder: 1,
                note: "如果近期不看剧，可以先取消自动续费。"
            ),
            ExpiryItem(
                title: "耳机保修",
                category: .warranty,
                expireDate: calendar.date(byAdding: .day, value: 27, to: .now) ?? .now,
                customOrder: 2,
                reminderPresets: [.sevenDaysBefore, .oneDayBefore]
            ),
            ExpiryItem(
                title: "感冒药保质期",
                category: .foodMedicine,
                expireDate: calendar.date(byAdding: .day, value: -4, to: .now) ?? .now,
                customOrder: 3,
                reminderEnabled: false,
                reminderPresets: []
            )
        ]

        sampleItems.forEach(context.insert)
        try? context.save()
    }
}
