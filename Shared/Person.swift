import Foundation
import SwiftData

@Model
final class Person {
    var id: UUID
    var name: String
    var birthMonth: Int          // 1...12
    var birthDay: Int            // 1...31
    var birthYear: Int?          // optional, lets us show "turns 30"
    var emoji: String?
    var notes: String?
    var lastAcknowledgedYear: Int?

    init(
        id: UUID = UUID(),
        name: String,
        birthMonth: Int,
        birthDay: Int,
        birthYear: Int? = nil,
        emoji: String? = "🎂",
        notes: String? = nil,
        lastAcknowledgedYear: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.birthMonth = birthMonth
        self.birthDay = birthDay
        self.birthYear = birthYear
        self.emoji = emoji
        self.notes = notes
        self.lastAcknowledgedYear = lastAcknowledgedYear

        // A freshly added (or freshly re-dated) birthday shouldn't retroactively count as
        // overdue for an occurrence that already passed before it existed in the app —
        // only occurrences that pass *after* this point should ever become overdue.
        if lastAcknowledgedYear == nil {
            resetAcknowledgementForCurrentBirthday()
        }
    }

    /// Is today this person's birthday?
    var isBirthdayToday: Bool {
        let today = Calendar.current.dateComponents([.month, .day], from: Date())
        return today.month == birthMonth && today.day == birthDay
    }

    /// Has this year's occurrence already been acknowledged?
    var isAcknowledgedThisYear: Bool {
        let currentYear = Calendar.current.component(.year, from: Date())
        return lastAcknowledgedYear == currentYear
    }

    /// Age they turn this year, if birth year is known.
    var turningAge: Int? {
        guard let birthYear else { return nil }
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - birthYear
    }

    /// Days until the next occurrence of this birthday (0 if today).
    var daysUntilNextBirthday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var components = calendar.dateComponents([.year], from: today)
        components.month = birthMonth
        components.day = birthDay

        guard var nextDate = calendar.date(from: components) else { return Int.max }
        if nextDate < today {
            components.year = (components.year ?? 0) + 1
            nextDate = calendar.date(from: components) ?? nextDate
        }
        return calendar.dateComponents([.day], from: today, to: nextDate).day ?? Int.max
    }

    /// This year's calendar day for the birthday, clamped to Feb 28 in non-leap years
    /// for people born on Feb 29 (so they don't just vanish from overdue tracking).
    private var thisYearOccurrenceDay: Int {
        guard birthMonth == 2, birthDay == 29 else { return birthDay }
        let year = Calendar.current.component(.year, from: Date())
        let isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
        return isLeap ? 29 : 28
    }

    /// True if this year's occurrence already passed, isn't today, and hasn't been
    /// acknowledged. Self-resets each year — once the next occurrence arrives it becomes
    /// `isBirthdayToday` instead, so this never accumulates multi-year backlog.
    var isOverdue: Bool {
        guard !isBirthdayToday, !isAcknowledgedThisYear else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let year = calendar.component(.year, from: today)
        let components = DateComponents(year: year, month: birthMonth, day: thisYearOccurrenceDay)
        guard let occurrence = calendar.date(from: components) else { return false }
        return occurrence < today
    }

    /// Days since this year's occurrence passed, if overdue.
    var daysOverdue: Int? {
        guard isOverdue else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let year = calendar.component(.year, from: today)
        let components = DateComponents(year: year, month: birthMonth, day: thisYearOccurrenceDay)
        guard let occurrence = calendar.date(from: components) else { return nil }
        return calendar.dateComponents([.day], from: occurrence, to: today).day
    }

    func acknowledgeThisYear() {
        lastAcknowledgedYear = Calendar.current.component(.year, from: Date())
    }

    func unacknowledgeThisYear() {
        lastAcknowledgedYear = nil
    }

    /// Call whenever the birth month/day is set or changed (creation or edit). If this
    /// year's occurrence already passed (and isn't today), treats it as already handled
    /// so it doesn't instantly show up as overdue backlog; otherwise leaves it unacknowledged
    /// so it shows normally as an upcoming/today birthday when its date arrives.
    func resetAcknowledgementForCurrentBirthday() {
        guard !isBirthdayToday else {
            lastAcknowledgedYear = nil
            return
        }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let year = calendar.component(.year, from: today)
        let components = DateComponents(year: year, month: birthMonth, day: thisYearOccurrenceDay)
        if let occurrence = calendar.date(from: components), occurrence < today {
            lastAcknowledgedYear = year
        } else {
            lastAcknowledgedYear = nil
        }
    }
}
