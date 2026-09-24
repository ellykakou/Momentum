import SwiftUI
import SwiftData

struct SummaryView: View {
    @Query private var sessions: [FocusSession]
    @Query private var goals: [DailyGoal]
    @Query private var tasks: [TaskItem]

    private var calendar: Calendar { .current }
    private var today: Date { calendar.startOfDay(for: Date()) }
    private var weekStart: Date { calendar.date(byAdding: .day, value: -6, to: today)! }
    private var fourteenStart: Date { calendar.date(byAdding: .day, value: -13, to: today)! }

    private var completedSessionsThisWeek: [FocusSession] {
        sessions.filter { session in
            session.isCompleted && (session.startedAt.map { $0 >= weekStart && $0 < tomorrow } ?? false)
        }
    }
    private var tomorrow: Date { calendar.date(byAdding: .day, value: 1, to: today)! }
    private var weekGoals: [DailyGoal] { goals.filter { $0.date >= weekStart && $0.date < tomorrow } }
    private var completedOutcomes: Int {
        weekGoals.reduce(0) { count, goal in
            count + goal.outcomes.filter { task in
                task.completedAt.map { calendar.isDate($0, inSameDayAs: goal.date) } ?? false
            }.count
        }
    }
    private var chosenOutcomes: Int { weekGoals.reduce(0) { $0 + $1.outcomes.count } }
    private var productiveDays: Int {
        (0..<14).filter { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: fourteenStart)!
            let focused = sessions.contains { session in
                session.isCompleted && (session.startedAt.map { calendar.isDate($0, inSameDayAs: date) } ?? false)
            }
            let outcome = goals.filter { calendar.isDate($0.date, inSameDayAs: date) }
                .flatMap(\.outcomes)
                .contains { task in task.completedAt.map { calendar.isDate($0, inSameDayAs: date) } ?? false }
            return focused || outcome
        }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Last 7 days · \(weekStart.formatted(date: .abbreviated, time: .omitted))–today") {
                    metric("Focused time", value: "\(Int(completedSessionsThisWeek.reduce(0) { $0 + $1.actualDurationSeconds } / 60)) min",
                           sample: "\(completedSessionsThisWeek.count) completed sessions")
                    metric("Chosen outcomes completed", value: "\(completedOutcomes) / \(chosenOutcomes)",
                           sample: "\(weekGoals.count) planned days")
                    if !completedSessionsThisWeek.isEmpty {
                        let average = completedSessionsThisWeek.reduce(0) { $0 + $1.actualDurationSeconds } / Double(completedSessionsThisWeek.count) / 60
                        metric("Average session", value: "\(Int(average.rounded())) min",
                               sample: "\(completedSessionsThisWeek.count) completed sessions")
                    }
                }
                Section("Last 14 days") {
                    metric("Productive days", value: "\(productiveDays) / 14",
                           sample: "14 calendar days")
                    Text("A productive day here means at least one completed focus session or one chosen outcome completed that day.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Text("These are descriptions of your records. They do not show what caused a change.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Summary")
        }
    }

    private func metric(_ title: String, value: String, sample: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.subheadline)
            Text(value).font(.title2.bold())
            Text(sample).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
