import Foundation

enum AppFormatters {
    static let fullDate: Date.FormatStyle = .dateTime.year().month(.wide).day()
    static let shortDate: Date.FormatStyle = .dateTime.month().day()

    static func countdownText(daysRemaining: Int) -> String {
        switch daysRemaining {
        case 0:
            return "今天"
        case let value where value > 0:
            return "剩余 \(value) 天"
        default:
            return "过期 \(abs(daysRemaining)) 天"
        }
    }

    static func reminderSummary(for item: ExpiryItem) -> String {
        guard item.reminderEnabled, !item.reminderPresets.isEmpty else {
            return "未开启提醒"
        }

        return item.reminderPresets.map(\.title).joined(separator: "、")
    }
}
