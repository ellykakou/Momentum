import Foundation

enum TaskSuggester {
    static func ranked(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.filter { $0.status != .done }
            .sorted {
                let left = score($0), right = score($1)
                if left != right { return left > right }
                if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
                return $0.id.uuidString < $1.id.uuidString
            }
    }

    private static func score(_ task: TaskItem) -> Int {
        // Missing ratings are neutral; shorter/lower-effort work wins close ties.
        (task.importance ?? 3) * 4 + (task.urgency ?? 3) * 3
        - (task.effortEstimate ?? 3)
        + (task.status == .mainQuest ? 6 : task.status == .next ? 3 : 0)
        + (task.durationEstimateMinutes.map { $0 <= 15 ? 2 : 0 } ?? 0)
    }

    static func reason(for task: TaskItem) -> String {
        if task.status == .mainQuest { return "Your Main Quest is a good place to start." }
        if (task.urgency ?? 0) >= 4 { return "High urgency on your list." }
        if (task.effortEstimate ?? 5) <= 2 { return "A lower-effort next step." }
        return "Based on your priority ratings and current list."
    }
}
