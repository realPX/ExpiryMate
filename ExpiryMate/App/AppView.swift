import SwiftUI
import SwiftData

struct AppView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeededSampleData") private var hasSeededSampleData = false
    @AppStorage("autoArchiveExpiredItems") private var autoArchiveExpiredItems = false

    @State private var selectedTab: AppTab = .home
    @State private var selectedCategory: ExpiryCategory?
    @State private var presentedSheet: AppSheet?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(
                    selectedTab: $selectedTab,
                    selectedCategory: $selectedCategory,
                    onAddTap: { presentedSheet = .addItem }
                )
            }
            .tabItem { AppTab.home.label }
            .tag(AppTab.home)

            NavigationStack {
                ItemsView(
                    selectedCategory: $selectedCategory,
                    onAddTap: { presentedSheet = .addItem }
                )
            }
            .tabItem { AppTab.items.label }
            .tag(AppTab.items)

            NavigationStack {
                SettingsView()
            }
            .tabItem { AppTab.settings.label }
            .tag(AppTab.settings)
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .addItem:
                NavigationStack {
                    ItemEditorView()
                }
            }
        }
        .task {
            await bootstrapIfNeeded()
        }
    }

    @MainActor
    private func bootstrapIfNeeded() async {
        if !hasSeededSampleData {
            DemoSeeder.seedIfNeeded(using: modelContext)
            hasSeededSampleData = true
        }

        ItemMaintenanceService.shared.ensureCustomOrder(using: modelContext)

        if autoArchiveExpiredItems {
            _ = await ItemMaintenanceService.shared.autoArchiveEligibleItems(using: modelContext)
        }

        WidgetSyncService.sync(using: modelContext)
        await NotificationScheduler.shared.requestAuthorizationIfNeeded()
        await NotificationScheduler.shared.syncAll(using: modelContext)
    }
}
