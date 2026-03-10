import Foundation

enum ItemFilter: String, CaseIterable, Identifiable {
    case all
    case upcoming
    case expired
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .upcoming:
            return "待处理"
        case .expired:
            return "过期"
        case .archived:
            return "归档"
        }
    }
}
