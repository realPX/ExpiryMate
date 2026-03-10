import Foundation

struct WidgetSnapshot: Codable {
    struct SnapshotItem: Codable, Identifiable {
        let id: UUID
        let title: String
        let categoryRawValue: String
        let expireDate: Date
        let daysRemaining: Int
    }

    var generatedAt: Date
    var items: [SnapshotItem]

    static let empty = WidgetSnapshot(generatedAt: .now, items: [])
}

enum WidgetSnapshotStore {
    private static let filename = "widget-snapshot.json"

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID)?
            .appendingPathComponent(filename)
    }

    static func save(_ snapshot: WidgetSnapshot) throws {
        guard let fileURL else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }

    static func load() -> WidgetSnapshot {
        guard let fileURL,
              let data = try? Data(contentsOf: fileURL)
        else {
            return .empty
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(WidgetSnapshot.self, from: data)) ?? .empty
    }
}
