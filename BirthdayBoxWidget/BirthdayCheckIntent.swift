import AppIntents
import SwiftData
import WidgetKit
import Foundation

struct ToggleBirthdayIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Birthday Acknowledged"
    static var description = IntentDescription("Marks a person's birthday as acknowledged or not for this year.")

    @Parameter(title: "Person ID")
    var personID: String

    init() {}

    init(personID: String) {
        self.personID = personID
    }

    func perform() async throws -> some IntentResult {
        let context = ModelContext(PersistenceController.shared)
        guard let uuid = UUID(uuidString: personID) else {
            return .result()
        }

        let descriptor = FetchDescriptor<Person>(predicate: #Predicate { $0.id == uuid })
        if let person = try context.fetch(descriptor).first {
            if person.isAcknowledgedThisYear {
                person.unacknowledgeThisYear()
            } else {
                person.acknowledgeThisYear()
                NotificationManager.cancelEveningReminder(for: person)
            }
            try context.save()
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
