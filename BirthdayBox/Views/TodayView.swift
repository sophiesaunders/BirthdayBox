import SwiftUI
import SwiftData
import WidgetKit

struct TodayView: View {
    @Query private var people: [Person]
    @Environment(\.modelContext) private var modelContext

    static let overdueColor = Color(red: 0.7, green: 0.0, blue: 0.0)

    private var todaysPeople: [Person] {
        people.filter { $0.isBirthdayToday }
            .sorted { lhs, rhs in
                if lhs.isAcknowledgedThisYear != rhs.isAcknowledgedThisYear {
                    return !lhs.isAcknowledgedThisYear
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    private var overduePeople: [Person] {
        people.filter { $0.isOverdue }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            Group {
                if todaysPeople.isEmpty && overduePeople.isEmpty {
                    ContentUnavailableView(
                        "No birthdays today",
                        systemImage: "party.popper",
                        description: Text("Check back tomorrow!")
                    )
                } else {
                    List {
                        if !todaysPeople.isEmpty {
                            Section("Today") {
                                ForEach(todaysPeople) { person in
                                    BirthdayRow(person: person) {
                                        toggle(person)
                                    }
                                }
                            }
                        }
                        if !overduePeople.isEmpty {
                            Section {
                                ForEach(overduePeople) { person in
                                    BirthdayRow(person: person) {
                                        toggle(person)
                                    }
                                }
                            } header: {
                                Text("Overdue")
                                    .foregroundStyle(TodayView.overdueColor)
                            }
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
        }
        try? modelContext.save()
        NotificationManager.refreshEveningReminders(people: people)
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
                        .foregroundStyle(person.isOverdue ? TodayView.overdueColor : .primary)
                    if person.isOverdue, let daysOverdue = person.daysOverdue {
                        Text(daysOverdue == 1 ? " 1 day overdue" : " \(daysOverdue) days overdue")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if let age = person.turningAge {
                        Text(" Turning \(age)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                if let notes = person.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .opacity(person.isAcknowledgedThisYear ? 0.45 : 1.0)
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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Person.self, configurations: config)
    let today = Date()
    let month = Calendar.current.component(.month, from: today)
    let day = Calendar.current.component(.day, from: today)

    let julia = Person(name: "Julia", birthMonth: month, birthDay: day, birthYear: 1990, emoji: "🎂", notes: "Make a card")
    let sam = Person(name: "Sam", birthMonth: month, birthDay: day, emoji: "🎉")

    container.mainContext.insert(julia)
    container.mainContext.insert(sam)
    sam.acknowledgeThisYear()
    try? container.mainContext.save()

    return TodayView()
        .modelContainer(container)
}

#Preview("Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Person.self, configurations: config)
    return TodayView()
        .modelContainer(container)
}
