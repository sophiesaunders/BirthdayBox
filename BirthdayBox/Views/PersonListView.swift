import SwiftUI
import SwiftData
import WidgetKit

struct PersonListView: View {
    @Query(sort: \Person.name) private var people: [Person]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddSheet = false
    @State private var editingPerson: Person?

    private var sortedByUpcoming: [Person] {
        people.sorted { $0.daysUntilNextBirthday < $1.daysUntilNextBirthday }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedByUpcoming) { person in
                    Button {
                        editingPerson = person
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Text(person.emoji ?? "🎂")
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(person.name)
                                        .font(.body)
                                    Spacer()
                                    if person.daysUntilNextBirthday == 0 {
                                        Text("Today!").font(.caption.bold()).foregroundStyle(.orange)
                                    } else {
                                        Text("\(person.daysUntilNextBirthday)d")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Text(subtitle(for: person))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                    .contextMenu {
                        Button(role: .destructive) {
                            deletePerson(person)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Everyone")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditPersonView(person: nil)
            }
            .sheet(item: $editingPerson) { person in
                AddEditPersonView(person: person)
            }
            .overlay {
                if people.isEmpty {
                    ContentUnavailableView(
                        "No one yet",
                        systemImage: "person.badge.plus",
                        description: Text("Tap + to add the first birthday to track.")
                    )
                }
            }
        }
    }

    private func subtitle(for person: Person) -> String {
        let date = dateLabel(for: person)
        guard let notes = person.notes, !notes.isEmpty else { return date }
        return "\(date) · \(notes)"
    }

    private func dateLabel(for person: Person) -> String {
        var components = DateComponents()
        components.month = person.birthMonth
        components.day = person.birthDay
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            deletePerson(sortedByUpcoming[index])
        }
    }

    private func deletePerson(_ person: Person) {
        NotificationManager.cancelMorningNotification(for: person)
        NotificationManager.cancelEveningReminder(for: person)
        modelContext.delete(person)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Person.self, configurations: config)

    let julia = Person(name: "Julia", birthMonth: 7, birthDay: 6, birthYear: 1990, emoji: "🎂", notes: "Make a card")
    let annMarie = Person(name: "Ann Marie", birthMonth: 7, birthDay: 7, emoji: "🎂")
    let noNotes = Person(name: "Chris", birthMonth: 12, birthDay: 25, birthYear: 1985, emoji: "🎄")

    container.mainContext.insert(julia)
    container.mainContext.insert(annMarie)
    container.mainContext.insert(noNotes)

    return PersonListView()
        .modelContainer(container)
}
