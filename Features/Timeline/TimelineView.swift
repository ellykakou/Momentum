import SwiftUI
import SwiftData

private enum DayEvent: Identifiable {
    case session(FocusSession), checkIn(CheckIn), log(InputLog)
    var id: UUID {
        switch self {
        case .session(let item): item.id
        case .checkIn(let item): item.id
        case .log(let item): item.id
        }
    }
    var date: Date {
        switch self {
        case .session(let item): item.startedAt ?? .distantPast
        case .checkIn(let item): item.timestamp
        case .log(let item): item.timestamp
        }
    }
}

struct TimelineView: View {
    @Query private var sessions: [FocusSession]
    @Query private var checkIns: [CheckIn]
    @Query private var logs: [InputLog]
    @Query private var goals: [DailyGoal]
    @State private var day = Date()
    @State private var selectedSession: FocusSession?
    @State private var selectedCheckIn: CheckIn?
    @State private var selectedLog: InputLog?
    @State private var selectedGoal: DailyGoal?

    private var events: [DayEvent] {
        let calendar = Calendar.current
        return (
            sessions.filter { $0.startedAt.map { calendar.isDate($0, inSameDayAs: day) } ?? false }.map(DayEvent.session)
            + checkIns.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }.map(DayEvent.checkIn)
            + logs.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }.map(DayEvent.log)
        ).sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Day", selection: $day, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                if let goal = goals.first(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
                    Section("Day plan") {
                        Button("\(goal.outcomes.count) chosen outcomes · Edit or delete") {
                            selectedGoal = goal
                        }
                    }
                }
                Section("Chronological activity") {
                    if events.isEmpty {
                        Text("Nothing recorded on this day.").foregroundStyle(.secondary)
                    }
                    ForEach(events) { event in
                        Button { open(event) } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Text(event.date, format: .dateTime.hour().minute())
                                    .font(.caption.monospacedDigit())
                                    .frame(width: 65, alignment: .leading)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(title(for: event)).foregroundStyle(.primary)
                                    Text(detail(for: event))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Timeline")
            .sheet(item: $selectedSession) { FocusSessionEditor(session: $0) }
            .sheet(item: $selectedCheckIn) { CheckInEditor(checkIn: $0) }
            .sheet(item: $selectedLog) { InputLogEditor(log: $0) }
            .sheet(item: $selectedGoal) { DailyGoalEditor(goal: $0) }
        }
    }

    private func open(_ event: DayEvent) {
        switch event {
        case .session(let value): selectedSession = value
        case .checkIn(let value): selectedCheckIn = value
        case .log(let value): selectedLog = value
        }
    }

    private func title(for event: DayEvent) -> String {
        switch event {
        case .session(let value): return value.task?.title ?? "Deleted task's focus session"
        case .checkIn: return "Check-in"
        case .log(let value): return value.type.title
        }
    }

    private func detail(for event: DayEvent) -> String {
        switch event {
        case .session(let value):
            return "\(Int(value.elapsed() / 60)) min focused · \(value.isCompleted ? "completed" : value.isPaused ? "paused" : "in progress")"
        case .checkIn(let value):
            let ratings = [("focus", value.focus), ("energy", value.energy), ("mood", value.mood), ("difficulty", value.difficulty)]
                .compactMap { name, score in score.map { "\(name) \($0)/5" } }
            return ratings.isEmpty ? "No ratings" : ratings.joined(separator: " · ")
        case .log(let value):
            let amount = value.numericValue.map { String($0) }
            return [value.textValue, amount].compactMap { $0 }.joined(separator: " · ")
        }
    }
}

private struct DailyGoalEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.createdAt) private var tasks: [TaskItem]
    @Bindable var goal: DailyGoal
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Day", selection: $goal.date, displayedComponents: .date)
                Section("Outcomes · maximum 3") {
                    ForEach(tasks) { task in
                        Toggle(task.title, isOn: Binding(
                            get: { goal.outcomes.contains { $0.id == task.id } },
                            set: { selected in
                                if selected && goal.outcomes.count < 3 { goal.outcomes.append(task) }
                                else if !selected { goal.outcomes.removeAll { $0.id == task.id } }
                            }
                        ))
                    }
                }
                Button("Delete day plan", role: .destructive) { confirmDelete = true }
            }
            .navigationTitle("Edit day plan")
            .toolbar { Button("Done") { MomentumStore.save(context); dismiss() } }
            .confirmationDialog("Delete this day plan?", isPresented: $confirmDelete) {
                Button("Delete day plan", role: .destructive) {
                    context.delete(goal); MomentumStore.save(context); dismiss()
                }
            }
        }
    }
}
