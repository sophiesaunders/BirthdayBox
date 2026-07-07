# BirthdayBox

A birthday reminder app for iOS with a home-screen widget. Instead of just
telling you whose birthday it is, it tracks whether you've actually reached
out — a small, recurring checklist rather than a one-off alert.

## What it does

- **Track people and birthdays** — name, date, optional birth year, an emoji,
  and free-form notes (e.g. "loves handwritten cards").
- **Today view** — shows whoever's birthday it is right now, with a checkbox
  per person that represents "I've acknowledged them" (text, call, card,
  gift, whatever counts for that relationship).
- **Home-screen widget** — the same checklist, live on your home screen, with
  a tappable checkbox that updates in place — no need to open the app.
- **Smart notifications** — a morning nudge on the day, and a second nudge in
  the evening *only if* that person is still unchecked. Already handled it?
  No second notification.
- **Recurs automatically** — each birthday is stored once; the checklist
  resets itself every year without any extra setup.
- **Fully on-device** — no account, no server, no cloud dependency required.

## How it works

- **SwiftUI + SwiftData** for the interface and local storage.
- **App Group shared container** — the main app and the widget extension are
  separate processes, but both read/write the same on-disk SwiftData store
  via a shared App Group, so the widget is always showing live state.
- **WidgetKit + AppIntents** — the widget checkbox is a real interactive
  button (`Button(intent:)`), so tapping it toggles state directly from the
  home screen without launching the app.
- **UserNotifications** — the morning reminder is a native yearly-repeating
  local notification (iOS handles the recurrence). The evening reminder is
  scheduled fresh each day the app is opened, and cancelled immediately if
  you check the box — that's what makes it conditional.

## Project structure

```
BirthdayBox/
├── Shared/                 Model + persistence + notification logic
│                           (used by both the app and the widget)
├── BirthdayBoxApp/          Main app target: views for Today / Everyone / Add-Edit
└── BirthdayBoxWidget/       Widget extension: timeline provider, widget view, tap intent
```

## Requirements

- Xcode with iOS 17+ SDK (interactive widget buttons require it)
- iOS 17+ device or simulator

## TODO

- [ ] Dim the person's name once checked off under Today
- [ ] Automatically re-order the "Today" section so completed ones go to the bottom
- [ ] Fix weird behavior on macOS with the "e.g." part of the "Notes" when adding a new bday
- [ ] Commit and push to repo!!

## Future ideas

- [ ] Add the ability to add basic holidays (Mother's Day, Father's Day)
- [ ] Add an emoji picker option rather than expecting a string
- [ ] Create a logo / icon, add to the app
- [ ] Add the ability to give you a reminder ahead of time about an upcoming birthday
- [ ] Add the ability to add a one-time note, e.g. an idea for their upcoming birthday gift
- [ ] Add the ability to track "Overdue" birthdays as well (not checked off in time)
- [ ] Add the ability to change the background color of the widget + app
- [ ] Add a "today" shortcut to the "Add Person" form, so it auto-sets birthday to current date
- [ ] Improve the Month + Date fields for their birthday. Can we make it easier?
- [ ] Edge cases: Created without day, or without month, or tons of bdays on a day, or long emoji string set, or long name set, deleting a person??
- [ ] Add some top bar to the widget, or a single emoji rather than per-person, etc.
- [ ] An "upcoming" birthdays section of the app?
- [ ] Make notifications configurable in the app!! Could be options for in the morning, and for in the evening (for whatever isn't complete) and you pick the time
