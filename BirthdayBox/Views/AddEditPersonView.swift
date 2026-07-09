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
    @State private var showingEmojiPicker = false

    private let months = Array(1...12)
    private let days = Array(1...31)
    private let years = Array(1900...Calendar.current.component(.year, from: Date())).map { String($0) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Person") {
                    TextField("Name", text: $name)
                    HStack {
                        Text("Emoji")
                        Spacer()
                        Button {
                            showingEmojiPicker = true
                        } label: {
                            Text(emoji)
                                .font(.system(size: 20))
                                .frame(width: 36, height: 36)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showingEmojiPicker) {
                            EmojiPickerView(selection: $emoji) {
                                showingEmojiPicker = false
                            }
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                }
                Section {
                    #if os(iOS)
                    HStack(spacing: 0) {
                        Picker("Month", selection: $month) {
                            ForEach(months, id: \.self) { Text(monthName($0)).tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()

                        Picker("Day", selection: $day) {
                            ForEach(days, id: \.self) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                    }
                    .frame(height: 150)
                    .clipped()
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    #else
                    Picker("Month", selection: $month) {
                        ForEach(months, id: \.self) { Text(monthName($0)).tag($0) }
                    }
                    Picker("Day", selection: $day) {
                        ForEach(days, id: \.self) { Text("\($0)").tag($0) }
                    }
                    #endif
                    Toggle("I know their birth year", isOn: $includeYear)
                    if includeYear {
                        Picker("Year", selection: $yearString) {
                            ForEach(years, id: \.self) { Text($0).tag($0) }
                        }
                    }
                } header: {
                    HStack {
                        Text("Birthday")
                        Spacer()
                        Button("Set to Today") { setToToday() }
                            .font(.subheadline)
                            .textCase(nil)
                    }
                }
                Section("Notes") {
                    TextField("e.g. loves handwritten cards", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .formStyle(.grouped)
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
        .frame(minWidth: 380, idealWidth: 420, maxWidth: 480)
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
        }
        try? modelContext.save()
        refreshNotifications()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }

    private func refreshNotifications() {
        let allPeople = (try? modelContext.fetch(FetchDescriptor<Person>())) ?? []
        NotificationManager.refreshMorningNotifications(people: allPeople)
        NotificationManager.refreshEveningReminders(people: allPeople)
    }

    private func setToToday() {
        let today = Calendar.current.dateComponents([.month, .day], from: Date())
        month = today.month ?? month
        day = today.day ?? day
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        return formatter.monthSymbols[month - 1]
    }
}

#Preview("Add") {
    AddEditPersonView(person: nil)
        .modelContainer(for: Person.self, inMemory: true)
}

#Preview("Edit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Person.self, configurations: config)
    let julia = Person(name: "Julia", birthMonth: 7, birthDay: 6, birthYear: 1990, emoji: "🎂", notes: "Make a card")
    container.mainContext.insert(julia)

    return AddEditPersonView(person: julia)
        .modelContainer(container)
}
