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
        return all.filter { $0.isBirthdayToday }
            .sorted { lhs, rhs in
                if lhs.isAcknowledgedThisYear != rhs.isAcknowledgedThisYear {
                    return !lhs.isAcknowledgedThisYear
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            .map {
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

    /// Fixed per widget size (rather than derived from row height) so name text doesn't grow
    /// just because a larger widget happens to have more vertical room per row.
    static let smallNameFontSize: CGFloat = 15
    static let mediumNameFontSize: CGFloat = 17

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
            Image(systemName: "party.popper")
                .font(.title2)
                .foregroundStyle(.secondary)
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

        return GeometryReader { geo in
            let headerHeight: CGFloat = 20
            let headerSpacing: CGFloat = 2
            let extraCount = entry.people.count - displayed.count
            let overflowTopSpacing: CGFloat = extraCount > 0 ? 4 : 0
            let overflowHeight: CGFloat = extraCount > 0 ? 16 : 0
            let availableForRows = geo.size.height - headerHeight - headerSpacing - overflowHeight - overflowTopSpacing
            let effectiveRowCount = max(displayed.count, 3)
            let rowHeight = availableForRows / CGFloat(effectiveRowCount)

            VStack(alignment: .leading, spacing: 0) {
                Text("Birthdays Today")
                    .font(.footnote)
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
                            .truncationMode(.tail)
                            .opacity(person.isAcknowledged ? 0.45 : 1.0)
                        Spacer(minLength: 2)
                        Button(intent: ToggleBirthdayIntent(personID: person.id.uuidString)) {
                            Image(systemName: person.isAcknowledged ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 17))
                                .foregroundStyle(person.isAcknowledged ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.system(size: BirthdayBoxWidgetView.smallNameFontSize))
                    .frame(height: rowHeight, alignment: .center)
                }
                if extraCount > 0 {
                    Text("+\(extraCount) more today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, overflowTopSpacing)
                        .frame(height: overflowHeight + overflowTopSpacing, alignment: .bottom)
                }
            }
            .frame(width: geo.size.width, alignment: .topLeading)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    /// Medium widget: row height is still computed from actual available space (for
    /// vertical distribution), but the name text uses the same fixed font size as the
    /// small widget so text doesn't grow just because more space happens to be available.
    private var mediumLayout: some View {
        let maxRows = 4
        let displayed = Array(entry.people.prefix(maxRows))
        let extraCount = entry.people.count - displayed.count

        return GeometryReader { geo in
            let headerHeight: CGFloat = 20
            let headerSpacing: CGFloat = 4
            let overflowTopSpacing: CGFloat = extraCount > 0 ? 4 : 0
            let overflowHeight: CGFloat = extraCount > 0 ? 16 : 0
            let availableForRows = geo.size.height - headerHeight - headerSpacing - overflowHeight - overflowTopSpacing
            let effectiveRowCount = max(displayed.count, 3)
            let rowHeight = availableForRows / CGFloat(effectiveRowCount)
            let checkboxSize: CGFloat = 19

            VStack(alignment: .leading, spacing: 0) {
                Text("Birthdays Today")
                    .font(.footnote)
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
                    .font(.system(size: Self.mediumNameFontSize))
                    .frame(height: rowHeight, alignment: .center)
                }
                if extraCount > 0 {
                    Text("+\(extraCount) more today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, overflowTopSpacing)
                        .frame(height: overflowHeight + overflowTopSpacing, alignment: .bottom)
                }
            }
            .frame(width: geo.size.width, alignment: .topLeading)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 10)
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
