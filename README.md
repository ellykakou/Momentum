# Momentum MVP

Native SwiftUI iPhone app for iOS 17 or later. Data lives in a local SwiftData store. The project has no packages, networking, account, or device data integrations.

## Open and build

Open `../Momentum.xcodeproj` in Xcode and select the `Momentum` scheme. Set a signing team and change the example bundle identifier if installing on a device. The app targets iPhone only.

## Layout

- `App`: entry point and three-tab navigation.
- `Models`: six SwiftData records and small persisted-value enums.
- `Persistence`: explicit local container and day-plan lookup.
- `Features/Today`: short plan, task editor, quick add, and deterministic suggestion.
- `Features/Focus`: timer and session editor.
- `Features/Timeline`: chronological day view and log/check-in/day-plan editors.
- `Features/Summary`: descriptive seven-day and 14-day metrics.
- `Shared`: optional rating control.

## Product choices

- Main Quest may also be one of the three chosen outcomes.
- Today shows three Next tasks. Additional Next tasks appear in the collapsed Later group; quick add assigns Later once Next has three tasks.
- A productive day is a calendar day with a completed focus session or a chosen outcome completed on that day.
- Completed focus time is counted on the session's start day. Pauses are excluded from actual duration.
- Every log and rating can be left blank. A task title is the only required text entry.
- Deleting a task keeps its focus sessions, with the task link cleared. Each record can be edited or deleted in the UI.

No medical conclusions are generated. The summary only describes recorded activity and shows the count used for each metric.

