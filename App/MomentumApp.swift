import SwiftUI
import SwiftData

@main struct MomentumApp: App {
    private let container: ModelContainer = {
        do { return try MomentumStore.makeContainer() }
        catch { fatalError("Momentum could not open its local data store: \(error)") }
    }()

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
            TimelineView()
                .tabItem { Label("Timeline", systemImage: "list.bullet.rectangle") }
            SummaryView()
                .tabItem { Label("Summary", systemImage: "chart.bar") }
        }
        .tint(.indigo)
    }
}
