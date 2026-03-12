import Foundation
import SwiftData
import UserNotifications

final class NotificationScheduler {
    static let shared = NotificationScheduler()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorizationIfNeeded() async {
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func syncAll(using context: ModelContext) async {
        let descriptor = FetchDescriptor<ExpiryItem>(sortBy: [SortDescriptor(\ExpiryItem.expireDate)])
        let items = (try? context.fetch(descriptor)) ?? []

        for item in items {
            await sync(for: item)
        }
    }

    func sync(for item: ExpiryItem) async {
        cancel(for: item)

        guard item.reminderEnabled else { return }

        for preset in item.reminderPresets {
            guard let triggerDate = triggerDate(for: item, preset: preset), triggerDate > .now else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = "\(item.displayCategoryTitle)即将到期，记得处理。"
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: requestIdentifier(for: item, preset: preset),
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    func cancel(for item: ExpiryItem) {
        let identifiers = ReminderPreset.allCases.map { requestIdentifier(for: item, preset: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private func triggerDate(for item: ExpiryItem, preset: ReminderPreset) -> Date? {
        let calendar = Calendar.current
        let reminderDay = calendar.date(byAdding: .day, value: -preset.daysBefore, to: item.expireDate)
        return reminderDay.flatMap {
            calendar.date(
                bySettingHour: AppConstants.preferredReminderHour,
                minute: AppConstants.preferredReminderMinute,
                second: 0,
                of: $0
            )
        }
    }

    private func requestIdentifier(for item: ExpiryItem, preset: ReminderPreset) -> String {
        "expiry-item-\(item.id.uuidString)-\(preset.rawValue)"
    }
}
