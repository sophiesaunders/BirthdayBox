import SwiftUI
import SwiftData
import WidgetKit

struct TodayView: View {
    @Query private var people: [Person]
    @Environment(\.modelContext) private var modelContext

    private var todaysPeople: [Person] {
        people.filter { $0.isBirthdayToday }
    }

    var body: some View {
        NavigationStack {
            Group {
                if todaysPeople.isEmpty {
                    ContentUnavailableView(
                        "No birthdays today",
                        systemImage: "party.popper",
                        description: Text("Check back tomorrow!")
                    )
                } else {
                    List(todaysPeople) { person in
                        BirthdayRow(person: person) {
                            toggle(person)
                        }
                    }
                }
            }
            .navigationTitle("Today")
        }
    }

    private func toggle(_ person: Person) {
        if person.isAcknowledgedThisYear {
            person.unacknowledgeThisYear()
        } else {
            person.acknowledgeThisYear()
            NotificationManager.cancelEveningReminder(for: person)
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct BirthdayRow: View {
    let person: Person
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Text(person.emoji ?? "🎂")
                .font(.largeTitle)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(person.name)
                        .font(.headline)
                        .strikethrough(person.isAcknowledgedThisYear)
                        .foregroundStyle(person.isAcknowledgedThisYear ? .secondary : .primary)
                    if let age = person.turningAge {
                        Text("· Turning \(age)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .strikethrough(person.isAcknowledgedThisYear)
                    }
                }
                if let notes = person.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .strikethrough(person.isAcknowledgedThisYear)
                }
            }
            Spacer()
            Button(action: onToggle) {
                Image(systemName: person.isAcknowledgedThisYear ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(person.isAcknowledgedThisYear ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
