import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct BirthdayEntry: TimelineEntry {
    let date: Date
    let people: [PersonSnapshot]
}

/// A plain-data snapshot of a Person, since widget timeline entries must be simple, Sendable values.
struct PersonSnapshot: Identifiable {
    let id: UUID
    let name: String
    let emoji: String
    let isAcknowledged: Bool
    let turningAge: Int?
}

struct BirthdayProvider: TimelineProvider {
    func placeholder(in context: Context) -> BirthdayEntry {
        BirthdayEntry(date: Date(), people: [
            PersonSnapshot(id: UUID(), name: "Sam", emoji: "🎂", isAcknowledged: false, turningAge: 30)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (BirthdayEntry) -> Void) {
        completion(BirthdayEntry(date: Date(), people: fetchTodaysPeople()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BirthdayEntry>) -> Void) {
        let entry = BirthdayEntry(date: Date(), people: fetchTodaysPeople())
        // Refresh at the next midnight so "today's birthdays" rolls over correctly.
        let midnight = Calendar.current.nextDate(
            after: Date(), matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func fetchTodaysPeople() -> [PersonSnapshot] {
        let context = ModelContext(PersistenceController.shared)
        let all = (try? context.fetch(FetchDescriptor<Person>())) ?? []
        return all.filter { $0.isBirthdayToday }.map {
            PersonSnapshot(
                id: $0.id,
                name: $0.name,
                emoji: $0.emoji ?? "🎂",
                isAcknowledged: $0.isAcknowledgedThisYear,
                turningAge: $0.turningAge
            )
        }
    }
}

struct BirthdayBoxWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: BirthdayProvider.Entry

    var body: some View {
        if entry.people.isEmpty {
            emptyState
        } else {
            switch family {
            case .systemSmall:
                smallLayout
            default:
                mediumLayout
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("🎉").font(.title)
            Text("No birthdays today")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
    }

    /// Small widget: just today's first birthday, compact and legible.
    /// If there's more than one, a small "+N more" hint is added below.
    private var smallLayout: some View {
        let person = entry.people[0]
        let extraCount = entry.people.count - 1

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(person.emoji)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 1) {
                    Text(person.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if let age = person.turningAge {
                        Text("Turning \(age)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 2)
                Button(intent: ToggleBirthdayIntent(personID: person.id.uuidString)) {
                    Image(systemName: person.isAcknowledged ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(person.isAcknowledged ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }
            if extraCount > 0 {
                Text("+\(extraCount) more today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(10)
    }

    /// Medium widget: up to three people in a list, each with its own checkbox.
    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(entry.people.prefix(3)) { person in
                HStack {
                    Text(person.emoji)
                    VStack(alignment: .leading) {
                        Text(person.name).font(.headline).lineLimit(1)
                        if let age = person.turningAge {
                            Text("Turning \(age)").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button(intent: ToggleBirthdayIntent(personID: person.id.uuidString)) {
                        Image(systemName: person.isAcknowledged ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(person.isAcknowledged ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
    }
}

struct BirthdayBoxWidget: Widget {
    let kind: String = "BirthdayBoxWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BirthdayProvider()) { entry in
            BirthdayBoxWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Birthdays")
        .description("See and check off today's birthdays.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

@main
struct BirthdayBoxWidgetBundle: WidgetBundle {
    var body: some Widget {
        BirthdayBoxWidget()
    }
}
