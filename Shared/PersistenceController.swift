import Foundation
import SwiftData

enum AppGroup {
    static let identifier = "group.com.sophiesaunders.birthdaybox"
}

enum PersistenceController {
    /// A single shared ModelContainer used by both the main app and the widget extension,
    /// backed by a SQLite store living in the shared App Group container.
    static let shared: ModelContainer = {
        let schema = Schema([Person.self])

        guard let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)
        else {
            fatalError("Could not find App Group container. Did you set up the App Group capability in Xcode?")
        }

        let storeURL = groupURL.appendingPathComponent("BirthdayBox.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create shared ModelContainer: \(error)")
        }
    }()
}
