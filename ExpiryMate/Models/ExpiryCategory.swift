import SwiftUI

enum ExpiryCategory: String, Codable, CaseIterable, Identifiable {
    case subscription
    case document
    case warranty
    case foodMedicine
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .subscription:
            return "订阅"
        case .document:
            return "证件"
        case .warranty:
            return "保修"
        case .foodMedicine:
            return "食品/药品"
        case .custom:
            return "自定义"
        }
    }

    var symbolName: String {
        switch self {
        case .subscription:
            return "creditcard"
        case .document:
            return "doc.text"
        case .warranty:
            return "checkmark.shield"
        case .foodMedicine:
            return "cross.case"
        case .custom:
            return "tag"
        }
    }

    var tint: Color {
        switch self {
        case .subscription:
            return Color(red: 0.67, green: 0.57, blue: 0.60)
        case .document:
            return Color(red: 0.55, green: 0.63, blue: 0.67)
        case .warranty:
            return Color(red: 0.53, green: 0.66, blue: 0.55)
        case .foodMedicine:
            return Color(red: 0.79, green: 0.60, blue: 0.44)
        case .custom:
            return Color(red: 0.53, green: 0.67, blue: 0.63)
        }
    }
}
