import SwiftUI
import SwiftData
import WidgetKit

struct AddEditPersonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: Person?

    @State private var name: String = ""
    @State private var month: Int = 1
    @State private var day: Int = 1
    @State private var includeYear: Bool = false
    @State private var yearString: String = "1990"
    @State private var emoji: String = "🎂"
    @State private var notes: String = ""

    private let months = Array(1...12)
    private let days = Array(1...31)
    private let years = Array((1900...Calendar.current.component(.year, from: Date())).reversed()).map { String($0) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Person") {
                    TextField("Name", text: $name)
                    TextField("Emoji", text: $emoji)
                }
                Section("Birthday") {
                    Picker("Month", selection: $month) {
                        ForEach(months, id: \.self) { Text(monthName($0)).tag($0) }
                    }
                    Picker("Day", selection: $day) {
                        ForEach(days, id: \.self) { Text("\($0)").tag($0) }
                    }
                    Toggle("I know their birth year", isOn: $includeYear)
                    if includeYear {
                        Picker("Year", selection: $yearString) {
                            ForEach(years, id: \.self) { Text($0).tag($0) }
                        }
                    }
                }
                Section("Notes") {
                    TextField("e.g. loves handwritten cards", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(person == nil ? "Add Person" : "Edit Person")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard let person else { return }
        name = person.name
        month = person.birthMonth
        day = person.birthDay
        emoji = person.emoji ?? "🎂"
        notes = person.notes ?? ""
        if let birthYear = person.birthYear {
            includeYear = true
            yearString = String(birthYear)
        }
    }

    private func save() {
        if let person {
            person.name = name
            person.birthMonth = month
            person.birthDay = day
            person.birthYear = includeYear ? Int(yearString) : nil
            person.emoji = emoji
            person.notes = notes
            NotificationManager.cancelMorningNotification(for: person)
            NotificationManager.scheduleMorningNotification(for: person)
        } else {
            let newPerson = Person(
                name: name,
                birthMonth: month,
                birthDay: day,
                birthYear: includeYear ? Int(yearString) : nil,
                emoji: emoji,
                notes: notes
            )
            modelContext.insert(newPerson)
            NotificationManager.scheduleMorningNotification(for: newPerson)
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        return formatter.monthSymbols[month - 1]
    }
}
