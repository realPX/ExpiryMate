import Foundation

enum ItemSortMode: String, CaseIterable, Identifiable {
    case dueDateAscending
    case dueDateDescending
    case recentlyUpdated
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dueDateAscending:
            return "到期日升序"
        case .dueDateDescending:
            return "到期日降序"
        case .recentlyUpdated:
            return "最近编辑"
        case .custom:
            return "自定义排序"
        }
    }

    var shortTitle: String {
        switch self {
        case .dueDateAscending:
            return "升序"
        case .dueDateDescending:
            return "降序"
        case .recentlyUpdated:
            return "最近编辑"
        case .custom:
            return "自定义"
        }
    }

    var symbolName: String {
        switch self {
        case .dueDateAscending:
            return "calendar.badge.clock"
        case .dueDateDescending:
            return "calendar.badge.exclamationmark"
        case .recentlyUpdated:
            return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .custom:
            return "arrow.up.and.down.text.horizontal"
        }
    }
}
