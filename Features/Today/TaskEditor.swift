import SwiftUI
import SwiftData

struct TaskEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Tag.label) private var tags: [Tag]
    @Query private var allTasks: [TaskItem]
    @Bindable var task: TaskItem
    @State private var titleDraft = ""
    @State private var newTag = ""
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $titleDraft)
                    TextField("Notes (optional)", text: Binding(
                        get: { task.notes ?? "" },
                        set: { task.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    Picker("Place", selection: Binding(
                        get: { task.status },
                        set: { setStatus($0) }
                    )) {
                        ForEach(TaskStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                }
                Section("Priority (optional)") {
                    OptionalRatingPicker(title: "Importance", value: $task.importance)
                    OptionalRatingPicker(title: "Urgency", value: $task.urgency)
                    OptionalRatingPicker(title: "Effort", value: $task.effortEstimate)
                    Stepper("Estimate: \(task.durationEstimateMinutes.map { "\($0) min" } ?? "None")", value: Binding(
                        get: { task.durationEstimateMinutes ?? 0 },
                        set: { task.durationEstimateMinutes = $0 == 0 ? nil : $0 }
                    ), in: 0...480, step: 5)
                }
                Section("Tags") {
                    ForEach(tags) { tag in
                        Toggle(tag.label, isOn: Binding(
                            get: { task.tags.contains { $0.id == tag.id } },
                            set: { selected in
                                if selected { task.tags.append(tag) }
                                else { task.tags.removeAll { $0.id == tag.id } }
                            }
                        ))
                    }
                    HStack {
                        TextField("New tag", text: $newTag)
                        Button("Add") { addTag() }
                            .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    NavigationLink("Manage tags") { TagManager() }
                }
                Section {
                    Button("Delete task", role: .destructive) { confirmDelete = true }
                }
            }
            .navigationTitle("Edit task")
            .toolbar { Button("Done") { finish() }
                .disabled(titleDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .onAppear { titleDraft = task.title }
            .confirmationDialog("Delete this task?", isPresented: $confirmDelete) {
                Button("Delete task", role: .destructive) {
                    context.delete(task)
                    MomentumStore.save(context)
                    dismiss()
                }
            }
        }
    }

    private func setStatus(_ status: TaskStatus) {
        if status == .mainQuest {
            for other in allTasks where other.id != task.id && other.status == .mainQuest {
                other.status = .next
            }
        }
        task.status = status
    }

    private func addTag() {
        let label = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty else { return }
        let tag = tags.first { $0.label.caseInsensitiveCompare(label) == .orderedSame } ?? Tag(label: label)
        if tag.modelContext == nil { context.insert(tag) }
        if !task.tags.contains(where: { $0.id == tag.id }) { task.tags.append(tag) }
        newTag = ""
        MomentumStore.save(context)
    }

    private func finish() {
        let title = titleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        task.title = title
        task.updatedAt = Date()
        MomentumStore.save(context)
        dismiss()
    }
}

private struct TagManager: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Tag.label) private var tags: [Tag]
    var body: some View {
        List {
            ForEach(tags) { tag in
                TextField("Label", text: Binding(
                    get: { tag.label },
                    set: { tag.label = $0; MomentumStore.save(context) }
                ))
            }
            .onDelete { offsets in
                for index in offsets { context.delete(tags[index]) }
                MomentumStore.save(context)
            }
        }
        .navigationTitle("Tags")
    }
}
