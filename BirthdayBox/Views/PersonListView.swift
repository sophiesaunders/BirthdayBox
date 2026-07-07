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
                                Text(dateLabel(for: person))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let notes = person.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                    .foregroundStyle(.primary)
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
            let person = sortedByUpcoming[index]
            NotificationManager.cancelMorningNotification(for: person)
            NotificationManager.cancelEveningReminder(for: person)
            modelContext.delete(person)
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
