import SwiftUI
import SwiftData

@main
struct ExpiryMateApp: App {
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([ExpiryItem.self])
        let configuration = ModelConfiguration()
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .modelContainer(sharedModelContainer)
    }
}
