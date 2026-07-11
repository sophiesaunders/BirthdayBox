# BirthdayBox

A birthday reminder app for iOS and macOS with a home-screen widget. Instead of
just telling you whose birthday it is, it tracks whether you've actually reached
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

- Xcode with iOS 18+ SDK (interactive widget buttons require it)
- iOS or macOS 18+ device or simulator

## Features

- [ ] Add Person: Add basic holidays (Mother's Day, Father's Day)
- [ ] Display: Get a reminder ahead of time about an upcoming birthday (maybe optional)
- [ ] General: Add a color background to the widget? And/or the app? Configurable?
- [ ] Emojis: Eliminate the custom emoji picker, figure out another macOS solution
- [ ] Add lock screen widget functionality
- [ ] Allow import of birthdays from contacts

## Testing

- [x] Notifications - morning and night
- [x] Add Person: What if no date is set? -> Has default value, not possible
- [x] Add Person: What if an invalid date is set? -> Jumps to next legitimate date
- [x] Add Person: What if no name is set? -> "Save" button is grayed out
- [x] Today: What if their name is longer than the space allowed?
- [x] Today: What if their emoji is longer than 1 character, or not an emoji?
- [ ] Today: What if the "Notes" are longer than the space allowed?
- [x] Today: 0, 1, 2, 3, 4, etc. birthdays appearance
- [x] Everyone: Delete a person
