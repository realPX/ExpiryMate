import SwiftUI

enum ExpiryCategory: String, Codable, CaseIterable, Identifiable {
    case subscription
    case document
    case warranty
    case foodMedicine

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
        }
    }

    var tint: Color {
        switch self {
        case .subscription:
            return .purple
        case .document:
            return .blue
        case .warranty:
            return .green
        case .foodMedicine:
            return .orange
        }
    }
}
