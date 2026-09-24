import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.createdAt) private var tasks: [TaskItem]
    @Query private var goals: [DailyGoal]
    @State private var taskTitle = ""
    @State private var selectedTask: TaskItem?
    @State private var selectedLog: InputLog?
    @State private var selectedCheckIn: CheckIn?
    @State private var focusTask: TaskItem?
    @State private var showOutcomePicker = false
    @State private var showSuggestion = false
    @State private var suggestionIndex = 0

    private var today: Date { Calendar.current.startOfDay(for: Date()) }
    private var goal: DailyGoal? { goals.first { Calendar.current.isDate($0.date, inSameDayAs: today) } }
    private var quest: TaskItem? { tasks.first { $0.status == .mainQuest } }
    private var next: [TaskItem] { Array(tasks.filter { $0.status == .next }.prefix(3)) }
    private var later: [TaskItem] {
        let overflow = tasks.filter { $0.status == .next }.dropFirst(3)
        return Array(overflow) + tasks.filter { $0.status == .later }
    }
    private var candidates: [TaskItem] { TaskSuggester.ranked(tasks) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.subheadline).foregroundStyle(.secondary)
                    questSection
                    outcomesSection
                    nextSection
                    suggestionSection
                    laterSection
                }
                .padding()
            }
            .navigationTitle("Today")
            .safeAreaInset(edge: .bottom) { quickAdd }
            .sheet(item: $selectedTask) { TaskEditor(task: $0) }
            .sheet(item: $selectedLog) { InputLogEditor(log: $0) }
            .sheet(item: $selectedCheckIn) { CheckInEditor(checkIn: $0) }
            .sheet(item: $focusTask) { FocusTimerView(task: $0) }
            .sheet(isPresented: $showOutcomePicker) {
                OutcomePicker(goalDate: today)
            }
        }
    }

    private var questSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Main Quest", systemImage: "flag.fill").font(.headline)
            if let quest {
                TaskCard(task: quest, onEdit: { selectedTask = quest }, onFocus: { focusTask = quest })
            } else {
                Text("Choose one thing that matters most today.")
                    .foregroundStyle(.secondary)
                if let first = next.first ?? later.first {
                    Button("Make \"\(first.title)\" Main Quest") { makeQuest(first) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.indigo.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
    }

    private var outcomesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Minimum Viable Day").font(.headline)
                Spacer()
                Button("Choose up to 3") { showOutcomePicker = true }
                    .font(.subheadline)
            }
            if let goal, !goal.outcomes.isEmpty {
                ForEach(goal.outcomes) { task in
                    HStack {
                        Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.status == .done ? .green : .secondary)
                        Button(task.title) { selectedTask = task }
                            .foregroundStyle(.primary)
                    }
                }
            } else {
                Text("One to three outcomes is enough.").foregroundStyle(.secondary)
            }
        }
    }

    private var nextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next").font(.headline)
            if next.isEmpty { Text("Your short list is clear.").foregroundStyle(.secondary) }
            ForEach(next) { task in
                TaskCard(task: task, onEdit: { selectedTask = task }, onFocus: { focusTask = task })
            }
        }
    }

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showSuggestion = true
                suggestionIndex = 0
            } label: {
                Label("What should I do now?", systemImage: "sparkle.magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            if showSuggestion, !candidates.isEmpty {
                let task = candidates[suggestionIndex % candidates.count]
                Text(task.title).font(.headline)
                Text(TaskSuggester.reason(for: task)).font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Start focus") { focusTask = task }
                    Button("Give me another") { suggestionIndex += 1 }
                        .disabled(candidates.count < 2)
                }
                .buttonStyle(.bordered)
            } else if showSuggestion {
                Text("Add a task to get a suggestion.").foregroundStyle(.secondary)
            }
        }
    }

    private var laterSection: some View {
        DisclosureGroup("Later (\(later.count))") {
            ForEach(later) { task in
                Button(task.title) { selectedTask = task }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 5)
            }
        }
    }

    private var quickAdd: some View {
        HStack(spacing: 10) {
            TextField("Add a task", text: $taskTitle)
                .submitLabel(.done)
                .onSubmit(addTask)
                .textFieldStyle(.roundedBorder)
            Button(action: addTask) { Image(systemName: "plus.circle.fill").font(.title2) }
                .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Save task")
            Menu {
                ForEach(InputKind.allCases) { kind in
                    Button(kind.title) { addLog(kind) }
                }
                Button("Check-in") { addCheckIn() }
            } label: {
                Image(systemName: "square.and.pencil").font(.title2)
            }
            .accessibilityLabel("Quick context log or check-in")
        }
        .padding(12)
        .background(.regularMaterial)
    }

    private func addTask() {
        let title = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        context.insert(TaskItem(title: title, status: next.count < 3 ? .next : .later))
        taskTitle = ""
        MomentumStore.save(context)
    }

    private func addLog(_ kind: InputKind) {
        let log = InputLog(type: kind)
        context.insert(log)
        MomentumStore.save(context)
        selectedLog = log
    }

    private func addCheckIn() {
        let checkIn = CheckIn()
        context.insert(checkIn)
        MomentumStore.save(context)
        selectedCheckIn = checkIn
    }

    private func makeQuest(_ task: TaskItem) {
        quest?.status = .next
        task.status = .mainQuest
        MomentumStore.save(context)
    }
}

private struct TaskCard: View {
    let task: TaskItem
    let onEdit: () -> Void
    let onFocus: () -> Void
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title).font(.body.weight(.medium))
                if let minutes = task.durationEstimateMinutes {
                    Text("About \(minutes) min").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Edit", action: onEdit).font(.caption)
            Button(action: onFocus) { Image(systemName: "play.circle.fill").font(.title2) }
                .accessibilityLabel("Focus on \(task.title)")
        }
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct OutcomePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.createdAt) private var tasks: [TaskItem]
    let goalDate: Date
    @State private var selected: [UUID] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(tasks.filter { $0.status != .done || selected.contains($0.id) }) { task in
                    Button {
                        if let index = selected.firstIndex(of: task.id) { selected.remove(at: index) }
                        else if selected.count < 3 { selected.append(task.id) }
                    } label: {
                        HStack {
                            Text(task.title).foregroundStyle(.primary)
                            Spacer()
                            if selected.contains(task.id) { Image(systemName: "checkmark") }
                        }
                    }
                }
            }
            .navigationTitle("Today's outcomes")
            .onAppear {
                if let goal = try? MomentumStore.goal(for: goalDate, in: context) {
                    selected = goal.outcomes.map(\.id)
                }
            }
            .toolbar {
                Button("Done") {
                    if let goal = try? MomentumStore.goal(for: goalDate, in: context) {
                        goal.outcomes = selected.compactMap { id in tasks.first { $0.id == id } }
                        MomentumStore.save(context)
                    }
                    dismiss()
                }
            }
        }
    }
}
