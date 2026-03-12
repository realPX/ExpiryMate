import Foundation

enum AppConstants {
    static let appName = "到期提醒管家"
    static let appGroupID = "group.com.example.expirymate"
    static let widgetKind = "ExpiryMateWidget"

    static let defaultReminderHourKey = "defaultReminderHour"
    static let defaultReminderMinuteKey = "defaultReminderMinute"
    static let widgetDisplayCountKey = "widgetDisplayCount"

    static let defaultReminderHour = 9
    static let defaultReminderMinute = 0
    static let defaultWidgetDisplayCount = 3

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static var preferredReminderHour: Int {
        let value = sharedDefaults.object(forKey: defaultReminderHourKey) as? Int ?? defaultReminderHour
        return (0...23).contains(value) ? value : defaultReminderHour
    }

    static var preferredReminderMinute: Int {
        let value = sharedDefaults.object(forKey: defaultReminderMinuteKey) as? Int ?? defaultReminderMinute
        return (0...59).contains(value) ? value : defaultReminderMinute
    }

    static var preferredWidgetDisplayCount: Int {
        let value = sharedDefaults.object(forKey: widgetDisplayCountKey) as? Int ?? defaultWidgetDisplayCount
        return min(max(value, 1), 3)
    }
}
