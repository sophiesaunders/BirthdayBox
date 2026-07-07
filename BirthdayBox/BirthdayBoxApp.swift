import SwiftUI
import SwiftData

@main
struct BirthdayBoxApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(PersistenceController.shared)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                NotificationManager.requestAuthorizationIfNeeded()
                refreshEveningReminders()
            }
        }
    }

    private func refreshEveningReminders() {
        let context = ModelContext(PersistenceController.shared)
        let people = (try? context.fetch(FetchDescriptor<Person>())) ?? []
        NotificationManager.refreshEveningReminders(people: people)
    }
}

/// Simple two-tab container for the main app.
struct RootTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "gift.fill") }
            PersonListView()
                .tabItem { Label("Everyone", systemImage: "person.2.fill") }
        }
    }
}

