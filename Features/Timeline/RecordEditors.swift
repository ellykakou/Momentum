import SwiftUI
import SwiftData

struct InputLogEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var log: InputLog
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: Binding(
                    get: { log.type }, set: { log.type = $0 }
                )) {
                    ForEach(InputKind.allCases) { kind in Text(kind.title).tag(kind) }
                }
                DatePicker("When", selection: $log.timestamp)
                TextField("Details (optional)", text: Binding(
                    get: { log.textValue ?? "" },
                    set: { log.textValue = $0.isEmpty ? nil : $0 }
                ))
                TextField("Amount (optional)", text: Binding(
                    get: { log.numericValue.map { String($0) } ?? "" },
                    set: { log.numericValue = Double($0) }
                ))
                .keyboardType(.decimalPad)
                Button("Delete log", role: .destructive) { confirmDelete = true }
            }
            .navigationTitle("Context log")
            .toolbar { Button("Done") { MomentumStore.save(context); dismiss() } }
            .confirmationDialog("Delete this log?", isPresented: $confirmDelete) {
                Button("Delete log", role: .destructive) {
                    context.delete(log); MomentumStore.save(context); dismiss()
                }
            }
        }
    }
}

struct CheckInEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var checkIn: CheckIn
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("When", selection: $checkIn.timestamp)
                Section("Ratings (optional)") {
                    RatingGroup(focus: $checkIn.focus, energy: $checkIn.energy,
                                mood: $checkIn.mood, difficulty: $checkIn.difficulty)
                }
                Button("Delete check-in", role: .destructive) { confirmDelete = true }
            }
            .navigationTitle("Check-in")
            .toolbar { Button("Done") { MomentumStore.save(context); dismiss() } }
            .confirmationDialog("Delete this check-in?", isPresented: $confirmDelete) {
                Button("Delete check-in", role: .destructive) {
                    context.delete(checkIn); MomentumStore.save(context); dismiss()
                }
            }
        }
    }
}
