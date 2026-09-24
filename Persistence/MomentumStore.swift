import Foundation
import SwiftData

enum MomentumStore {
    static let schema = Schema([
        TaskItem.self, FocusSession.self, CheckIn.self,
        InputLog.self, DailyGoal.self, Tag.self
    ])

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        // Explicitly keep the MVP in this app's local container.
        let configuration = ModelConfiguration(
            "MomentumLocal", schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func goal(for date: Date, in context: ModelContext) throws -> DailyGoal {
        let day = Calendar.current.startOfDay(for: date)
        let next = Calendar.current.date(byAdding: .day, value: 1, to: day)!
        let descriptor = FetchDescriptor<DailyGoal>(predicate: #Predicate { $0.date >= day && $0.date < next })
        if let existing = try context.fetch(descriptor).first { return existing }
        let goal = DailyGoal(date: day)
        context.insert(goal)
        return goal
    }

    static func save(_ context: ModelContext) {
        do { try context.save() }
        catch { assertionFailure("Unable to save local data: \(error)") }
    }
}
