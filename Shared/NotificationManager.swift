import Foundation
import UserNotifications

/// Handles scheduling and cancelling local notifications for birthdays.
///
/// Design:
/// - A repeating "morning" notification fires every year on the birthday itself.
///   Its content never needs to change, so a yearly `UNCalendarNotificationTrigger` handles
///   the recurrence natively — no app logic needed to keep it firing year after year.
/// - The "evening, only if still unchecked" notification is trickier, since notification
///   content is fixed at scheduling time — iOS can't check your data right before showing it.
///   Instead, we schedule a one-off evening notification each day the app is opened/foregrounded
///   for anyone whose birthday is today and isn't yet acknowledged, and we CANCEL it the moment
///   the person is checked off. That way it only ever fires if the box is still unchecked at
///   the evening hour.
///
///   Caveat: this means the evening reminder is only (re)armed when the app runs that day.
///   For most personal use this is fine (you'll open the app or tap the widget), but if you
///   want it to work even on days you never touch your phone until evening, a natural next
///   step is adding a BGAppRefreshTask that runs this same refresh logic in the background.
enum NotificationManager {

    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Morning notification (repeats every year automatically)

    static func scheduleMorningNotification(for person: Person, hour: Int = 9, minute: Int = 0) {
        let identifier = "morning-\(person.id.uuidString)"

        let content = UNMutableNotificationContent()
        content.title = "🎂 \(person.name)'s birthday"
        content.body = "Today's the day — reach out to \(person.name)!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.month = person.birthMonth
        dateComponents.day = person.birthDay
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    static func cancelMorningNotification(for person: Person) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["morning-\(person.id.uuidString)"]
        )
    }

    // MARK: - Evening "still unchecked" notification (one-off, rescheduled/cancelled dynamically)

    /// Call this once a day (e.g. on app launch/foreground) to set up today's conditional
    /// evening reminders for anyone whose birthday is today and not yet acknowledged.
    static func refreshEveningReminders(people: [Person], hour: Int = 19, minute: Int = 0) {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())

        for person in people {
            let identifier = eveningIdentifier(for: person, year: year)

            guard person.isBirthdayToday else {
                // Not their birthday today — make sure no stale evening reminder lingers.
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
                continue
            }

            if person.isAcknowledgedThisYear {
                // Already checked off — cancel the evening nudge, it's not needed.
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
                continue
            }

            // Still unchecked and it's their birthday today — schedule (or refresh) the evening nudge.
            let content = UNMutableNotificationContent()
            content.title = "🎁 Don't forget \(person.name)"
            content.body = "You haven't checked off \(person.name)'s birthday yet today."
            content.sound = .default

            var triggerDate = calendar.dateComponents([.year, .month, .day], from: Date())
            triggerDate.hour = hour
            triggerDate.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    /// Call this the moment a person is checked off, so the evening nudge doesn't fire.
    static func cancelEveningReminder(for person: Person) {
        let year = Calendar.current.component(.year, from: Date())
        let identifier = eveningIdentifier(for: person, year: year)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private static func eveningIdentifier(for person: Person, year: Int) -> String {
        "evening-\(person.id.uuidString)-\(year)"
    }
}
