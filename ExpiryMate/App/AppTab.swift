import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case items
    case settings

    var id: String { rawValue }

    @ViewBuilder
    var label: some View {
        switch self {
        case .home:
            Label("首页", systemImage: "sparkles.rectangle.stack")
        case .items:
            Label("全部", systemImage: "checklist")
        case .settings:
            Label("设置", systemImage: "gearshape")
        }
    }
}

enum AppSheet: String, Identifiable {
    case addItem

    var id: String { rawValue }
}
