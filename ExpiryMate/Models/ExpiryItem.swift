import Foundation
import SwiftData

@Model
final class ExpiryItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var categoryRawValue: String
    var expireDate: Date
    var customOrder: Int
    var reminderEnabled: Bool
    var reminderRawValue: String
    var note: String
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        category: ExpiryCategory,
        expireDate: Date,
        customOrder: Int = 0,
        reminderEnabled: Bool = true,
        reminderPresets: [ReminderPreset] = [.sameDay, .oneDayBefore],
        note: String = "",
        isArchived: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.categoryRawValue = category.rawValue
        self.expireDate = expireDate
        self.customOrder = customOrder
        self.reminderEnabled = reminderEnabled
        self.reminderRawValue = reminderPresets.map(\.rawValue).joined(separator: ",")
        self.note = note
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension ExpiryItem {
    var category: ExpiryCategory {
        get { ExpiryCategory(rawValue: categoryRawValue) ?? .subscription }
        set { categoryRawValue = newValue.rawValue }
    }

    var reminderPresets: [ReminderPreset] {
        get {
            reminderRawValue
                .split(separator: ",")
                .compactMap { ReminderPreset(rawValue: String($0)) }
                .sorted { $0.daysBefore < $1.daysBefore }
        }
        set {
            reminderRawValue = newValue
                .sorted { $0.daysBefore < $1.daysBefore }
                .map(\.rawValue)
                .joined(separator: ",")
        }
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.startOfDay(for: expireDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    var isExpired: Bool {
        daysRemaining < 0
    }

    var isDueToday: Bool {
        daysRemaining == 0
    }

    var isUpcoming: Bool {
        (0...7).contains(daysRemaining)
    }

    var statusText: String {
        if isDueToday {
            return "今天到期"
        }
        if daysRemaining > 0 {
            return "还有 \(daysRemaining) 天"
        }
        return "已过期 \(abs(daysRemaining)) 天"
    }

    func refreshUpdatedAt() {
        updatedAt = .now
    }
}
