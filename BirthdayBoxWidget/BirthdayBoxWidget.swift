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

    /// Small widget: today's birthdays, capped at 5. Row height is computed from the
    /// worst-case cap (5 rows), not the actual count today — so sizing stays consistent
    /// whether there's 1 birthday or 5, and rows sit at the top rather than stretching
    /// to fill (and centering awkwardly) when there are only 1-2 people.
    private var smallLayout: some View {
        let displayed = Array(entry.people.prefix(5))
        let extraCount = entry.people.count - displayed.count

        return GeometryReader { geo in
            let headerHeight: CGFloat = 18
            let headerSpacing: CGFloat = 8
            let availableForRows = geo.size.height - headerHeight - headerSpacing
            let effectiveRowCount = max(displayed.count, 3)
            let rowHeight = availableForRows / CGFloat(effectiveRowCount)
            let fontSize = max(min(rowHeight * 0.55, 19), 11)

            VStack(alignment: .leading, spacing: 0) {
                Text("Birthdays Today")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(height: headerHeight, alignment: .leading)
                    .padding(.bottom, headerSpacing)

                ForEach(displayed) { person in
                    HStack(spacing: 6) {
                        Text(person.emoji)
                        Text(person.name)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .opacity(person.isAcknowledged ? 0.45 : 1.0)
                        Spacer(minLength: 2)
                        Button(intent: ToggleBirthdayIntent(personID: person.id.uuidString)) {
                            Image(systemName: person.isAcknowledged ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(person.isAcknowledged ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.system(size: fontSize))
                    .frame(height: rowHeight, alignment: .center)
                }
                if extraCount > 0 {
                    Text("+\(extraCount) more today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(height: rowHeight * 0.6, alignment: .center)
                }
            }
            .frame(width: geo.size.width, alignment: .topLeading)
        }
        .padding(.horizontal, 14)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    /// Medium widget: same adaptive sizing approach as small — row height (and font size)
    /// is computed from actual available space rather than guessed, so we're not leaving
    /// room on the table. Capped at 4; anything beyond collapses into "+N more today."
    private var mediumLayout: some View {
        let maxRows = 4
        let displayed = Array(entry.people.prefix(maxRows))
        let extraCount = entry.people.count - displayed.count

        return GeometryReader { geo in
            let headerHeight: CGFloat = 18
            let headerSpacing: CGFloat = 8
            let overflowHeight: CGFloat = extraCount > 0 ? 16 : 0
            let availableForRows = geo.size.height - headerHeight - headerSpacing - overflowHeight
            let effectiveRowCount = max(displayed.count, 3)
            let rowHeight = availableForRows / CGFloat(effectiveRowCount)
            let fontSize = max(min(rowHeight * 0.55, 19), 12)
            let checkboxSize = max(fontSize + 4, 18)

            VStack(alignment: .leading, spacing: 0) {
                Text("Birthdays Today")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .frame(height: headerHeight, alignment: .leading)
                    .padding(.bottom, headerSpacing)

                ForEach(displayed) { person in
                    HStack(spacing: 10) {
                        Text(person.emoji)
                        HStack(spacing: 6) {
                            Text(person.name)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            if let age = person.turningAge {
                                Text("Turning \(age)")
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .opacity(person.isAcknowledged ? 0.45 : 1.0)
                        Spacer(minLength: 8)
                        Button(intent: ToggleBirthdayIntent(personID: person.id.uuidString)) {
                            Image(systemName: person.isAcknowledged ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: checkboxSize))
                                .foregroundStyle(person.isAcknowledged ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.system(size: fontSize))
                    .frame(height: rowHeight, alignment: .center)
                }
                if extraCount > 0 {
                    Text("+\(extraCount) more today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(height: overflowHeight, alignment: .leading)
                }
            }
            .frame(width: geo.size.width, alignment: .topLeading)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
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

#Preview("Small - 1 person", as: .systemSmall) {
    BirthdayBoxWidget()
} timeline: {
    BirthdayEntry(date: .now, people: [
        PersonSnapshot(id: UUID(), name: "Julia", emoji: "🎂", isAcknowledged: false, turningAge: 36)
    ])
}

#Preview("Small - 5 people", as: .systemSmall) {
    BirthdayBoxWidget()
} timeline: {
    BirthdayEntry(date: .now, people: [
        PersonSnapshot(id: UUID(), name: "Julia", emoji: "🎂", isAcknowledged: false, turningAge: 36),
        PersonSnapshot(id: UUID(), name: "Sam", emoji: "🎉", isAcknowledged: true, turningAge: nil),
        PersonSnapshot(id: UUID(), name: "Ann Marie", emoji: "🎈", isAcknowledged: false, turningAge: 28),
        PersonSnapshot(id: UUID(), name: "Chris", emoji: "🎄", isAcknowledged: false, turningAge: nil),
        PersonSnapshot(id: UUID(), name: "Morgan", emoji: "🥳", isAcknowledged: true, turningAge: 41)
    ])
}

#Preview("Small - empty", as: .systemSmall) {
    BirthdayBoxWidget()
} timeline: {
    BirthdayEntry(date: .now, people: [])
}

#Preview("Medium - 2 people", as: .systemMedium) {
    BirthdayBoxWidget()
} timeline: {
    BirthdayEntry(date: .now, people: [
        PersonSnapshot(id: UUID(), name: "Julia", emoji: "🎂", isAcknowledged: false, turningAge: 36),
        PersonSnapshot(id: UUID(), name: "Sam", emoji: "🎉", isAcknowledged: true, turningAge: nil)
    ])
}

#Preview("Medium - 4 people", as: .systemMedium) {
    BirthdayBoxWidget()
} timeline: {
    BirthdayEntry(date: .now, people: [
        PersonSnapshot(id: UUID(), name: "Julia", emoji: "🎂", isAcknowledged: false, turningAge: 36),
        PersonSnapshot(id: UUID(), name: "Sam", emoji: "🎉", isAcknowledged: true, turningAge: nil),
        PersonSnapshot(id: UUID(), name: "Ann Marie", emoji: "🎈", isAcknowledged: false, turningAge: 28),
        PersonSnapshot(id: UUID(), name: "Chris", emoji: "🎄", isAcknowledged: false, turningAge: nil)
    ])
}

#Preview("Medium - 6 people (overflow)", as: .systemMedium) {
    BirthdayBoxWidget()
} timeline: {
    BirthdayEntry(date: .now, people: [
        PersonSnapshot(id: UUID(), name: "Julia", emoji: "🎂", isAcknowledged: false, turningAge: 36),
        PersonSnapshot(id: UUID(), name: "Sam", emoji: "🎉", isAcknowledged: true, turningAge: nil),
        PersonSnapshot(id: UUID(), name: "Ann Marie", emoji: "🎈", isAcknowledged: false, turningAge: 28),
        PersonSnapshot(id: UUID(), name: "Chris", emoji: "🎄", isAcknowledged: false, turningAge: nil),
        PersonSnapshot(id: UUID(), name: "Morgan", emoji: "🥳", isAcknowledged: true, turningAge: 41),
        PersonSnapshot(id: UUID(), name: "Taylor", emoji: "🎁", isAcknowledged: false, turningAge: 22)
    ])
}
