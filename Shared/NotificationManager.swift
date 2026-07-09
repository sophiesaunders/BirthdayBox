import Foundation
import UserNotifications

/// Handles scheduling and cancelling local notifications for birthdays.
///
/// Design:
/// - Same-day birthdays are batched into a single notification each (one morning, one evening)
///   rather than one per person, so having several birthdays on the same day doesn't produce
///   a flood of separate notifications.
/// - The "morning" notification is keyed by month/day (not by person), since its content only
///   depends on who shares that calendar day — it repeats every year via `UNCalendarNotificationTrigger`.
///   Because its content lists names, it must be recomputed (removed + re-added) whenever the
///   set of people or their birthdays changes, not just once at add-time.
/// - The "evening, only if still unchecked" notification is trickier, since notification
///   content is fixed at scheduling time — iOS can't check your data right before showing it.
///   Instead, we recompute and reschedule a one-off evening notification each day the app is
///   opened/foregrounded (and after every acknowledge/unacknowledge), listing whoever's
///   birthday-today and still unchecked. If nobody remains unchecked, it's cancelled outright.
///
///   Caveat: this means the evening reminder is only (re)armed when the app runs that day.
///   For most personal use this is fine (you'll open the app or tap the widget), but if you
///   want it to work even on days you never touch your phone until evening, a natural next
///   step is adding a BGAppRefreshTask that runs this same refresh logic in the background.
enum NotificationManager {

    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Morning notifications (one per calendar day, repeats every year automatically)

    /// Call this whenever the set of people (or their birthdays) changes, so each day's
    /// morning notification reflects everyone who currently shares that birthday.
    static func refreshMorningNotifications(people: [Person], hour: Int = 9, minute: Int = 0) {
        let grouped = Dictionary(grouping: people) { "\($0.birthMonth)-\($0.birthDay)" }

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let existingIDs = requests.map(\.identifier).filter { $0.hasPrefix("morning-") }
            let validIDs = Set(grouped.keys.map { "morning-\($0)" })
            let staleIDs = existingIDs.filter { !validIDs.contains($0) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: staleIDs)

            for (key, group) in grouped {
                let identifier = "morning-\(key)"

                let content = UNMutableNotificationContent()
                if group.count == 1 {
                    content.title = "🎂 \(group[0].name)'s birthday"
                    content.body = "Today's the day — reach out to \(group[0].name)!"
                } else {
                    content.title = "🎂 \(group.count) birthdays today"
                    content.body = group.map(\.name).joined(separator: ", ")
                }
                content.sound = .default

                var dateComponents = DateComponents()
                dateComponents.month = group[0].birthMonth
                dateComponents.day = group[0].birthDay
                dateComponents.hour = hour
                dateComponents.minute = minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    // MARK: - Evening "still unchecked" notification (one-off, rescheduled/cancelled dynamically)

    /// Call this whenever today's acknowledgement state might have changed (app launch/foreground,
    /// checking/unchecking someone, adding/editing/deleting a person) to keep today's single
    /// evening reminder in sync with who's still unchecked.
    static func refreshEveningReminders(people: [Person], hour: Int = 19, minute: Int = 0) {
        let calendar = Calendar.current
        let today = Date()
        let identifier = eveningIdentifier(for: today)

        // Sweep away any stale "evening-" notifications left over from older app versions
        // (e.g. the old per-person scheme), since only `identifier` should ever be pending.
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let staleIDs = requests.map(\.identifier)
                .filter { $0.hasPrefix("evening-") && $0 != identifier }
            if !staleIDs.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: staleIDs)
            }
        }

        let unacknowledgedToday = people.filter { $0.isBirthdayToday && !$0.isAcknowledgedThisYear }

        guard !unacknowledgedToday.isEmpty else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "🔔 Don't forget \(unacknowledgedToday.map(\.name).joined(separator: ", "))"
        content.body = unacknowledgedToday.count == 1
            ? "You haven't checked off \(unacknowledgedToday[0].name)'s birthday yet today."
            : "You haven't checked off their birthdays yet today."
        content.sound = .default

        var triggerDate = calendar.dateComponents([.year, .month, .day], from: today)
        triggerDate.hour = hour
        triggerDate.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private static func eveningIdentifier(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "evening-\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}
