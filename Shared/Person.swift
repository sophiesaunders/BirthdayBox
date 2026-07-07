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

    func acknowledgeThisYear() {
        lastAcknowledgedYear = Calendar.current.component(.year, from: Date())
    }

    func unacknowledgeThisYear() {
        lastAcknowledgedYear = nil
    }
}
