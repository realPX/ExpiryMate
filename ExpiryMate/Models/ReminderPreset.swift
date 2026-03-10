import Foundation

enum ReminderPreset: String, Codable, CaseIterable, Identifiable {
    case sameDay
    case oneDayBefore
    case threeDaysBefore
    case sevenDaysBefore

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sameDay:
            return "到期当天"
        case .oneDayBefore:
            return "提前 1 天"
        case .threeDaysBefore:
            return "提前 3 天"
        case .sevenDaysBefore:
            return "提前 7 天"
        }
    }

    var daysBefore: Int {
        switch self {
        case .sameDay:
            return 0
        case .oneDayBefore:
            return 1
        case .threeDaysBefore:
            return 3
        case .sevenDaysBefore:
            return 7
        }
    }
}
