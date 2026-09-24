import SwiftUI
import SwiftData

struct FocusTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var sessions: [FocusSession]
    let task: TaskItem
    @State private var plannedMinutes = 25
    @State private var preFocus: Int?
    @State private var preEnergy: Int?
    @State private var preMood: Int?
    @State private var preDifficulty: Int?
    @State private var postFocus: Int?
    @State private var postEnergy: Int?
    @State private var postMood: Int?
    @State private var postDifficulty: Int?
    @State private var markTaskDone = false
    @State private var currentSession: FocusSession?

    private var activeSession: FocusSession? {
        // A single active timer avoids counting overlapping focus time twice.
        currentSession ?? sessions.first { $0.isStarted && !$0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(activeSession?.task?.title ?? task.title) {
                    if let session = activeSession {
                        SwiftUI.TimelineView(.periodic(from: .now, by: 1)) { timeline in
                            let elapsed = Int(session.elapsed(at: timeline.date))
                            let remaining = max(0, session.plannedDurationMinutes * 60 - elapsed)
                            VStack(alignment: .leading) {
                                Text(Duration.seconds(remaining).formatted(.time(pattern: .minuteSecond)))
                                    .font(.system(size: 50, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                Text("\(elapsed / 60) min focused · \(session.plannedDurationMinutes) min planned")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        HStack {
                            if session.isPaused {
                                Button("Resume") { session.resume(); MomentumStore.save(context) }
                            } else {
                                Button("Pause") { session.pause(); MomentumStore.save(context) }
                            }
                            Spacer()
                            Button("Complete") { complete(session) }
                                .buttonStyle(.borderedProminent)
                        }
                        Toggle("Also mark task done", isOn: $markTaskDone)
                    } else {
                        Stepper("Plan \(plannedMinutes) min", value: $plannedMinutes, in: 5...180, step: 5)
                        Button("Start focus") { start() }
                            .buttonStyle(.borderedProminent)
                    }
                }
                if activeSession == nil {
                    Section("Before (optional)") {
                        RatingGroup(focus: $preFocus, energy: $preEnergy, mood: $preMood, difficulty: $preDifficulty)
                    }
                } else {
                    Section("After (optional)") {
                        RatingGroup(focus: $postFocus, energy: $postEnergy, mood: $postMood, difficulty: $postDifficulty)
                    }
                }
                Text("You can leave every rating blank. Time keeps running if you close this screen.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("Focus")
            .toolbar { Button("Close") { dismiss() } }
            .onAppear { plannedMinutes = max(5, task.durationEstimateMinutes ?? 25) }
        }
    }

    private func start() {
        let session = FocusSession(task: task, plannedDurationMinutes: plannedMinutes)
        session.preFocus = preFocus
        session.preEnergy = preEnergy
        session.preMood = preMood
        session.preDifficulty = preDifficulty
        context.insert(session)
        session.start()
        currentSession = session
        MomentumStore.save(context)
    }

    private func complete(_ session: FocusSession) {
        session.postFocus = postFocus
        session.postEnergy = postEnergy
        session.postMood = postMood
        session.postDifficulty = postDifficulty
        session.complete()
        if markTaskDone { session.task?.status = .done }
        MomentumStore.save(context)
        dismiss()
    }
}

struct FocusSessionEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.createdAt) private var tasks: [TaskItem]
    @Bindable var session: FocusSession
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Work") {
                    Picker("Task", selection: Binding<UUID?>(
                        get: { session.task?.id },
                        set: { id in session.task = tasks.first { $0.id == id } }
                    )) {
                        Text("No task").tag(nil as UUID?)
                        ForEach(tasks) { task in Text(task.title).tag(task.id as UUID?) }
                    }
                    Stepper("Planned: \(session.plannedDurationMinutes) min", value: $session.plannedDurationMinutes, in: 1...480)
                    Stepper("Actual: \(Int(session.actualDurationSeconds / 60)) min", value: Binding(
                        get: { Int(session.actualDurationSeconds / 60) },
                        set: { session.actualDurationSeconds = Double($0 * 60) }
                    ), in: 0...1440)
                    Toggle("Started", isOn: $session.isStarted)
                    Toggle("Completed", isOn: $session.isCompleted)
                    DatePicker("Start", selection: Binding(
                        get: { session.startedAt ?? Date() },
                        set: { session.startedAt = $0 }
                    ))
                    Toggle("Has end time", isOn: Binding(
                        get: { session.endedAt != nil },
                        set: { session.endedAt = $0 ? Date() : nil }
                    ))
                    if session.endedAt != nil {
                        DatePicker("End", selection: Binding(
                            get: { session.endedAt ?? Date() },
                            set: { session.endedAt = $0 }
                        ))
                    }
                }
                Section("Before (optional)") {
                    RatingGroup(focus: $session.preFocus, energy: $session.preEnergy,
                                mood: $session.preMood, difficulty: $session.preDifficulty)
                }
                Section("After (optional)") {
                    RatingGroup(focus: $session.postFocus, energy: $session.postEnergy,
                                mood: $session.postMood, difficulty: $session.postDifficulty)
                }
                Section { Button("Delete session", role: .destructive) { confirmDelete = true } }
            }
            .navigationTitle("Edit session")
            .toolbar { Button("Done") { MomentumStore.save(context); dismiss() } }
            .confirmationDialog("Delete this session?", isPresented: $confirmDelete) {
                Button("Delete session", role: .destructive) {
                    context.delete(session); MomentumStore.save(context); dismiss()
                }
            }
        }
    }
}
