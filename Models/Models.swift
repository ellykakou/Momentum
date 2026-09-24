import Foundation
import SwiftData

enum TaskStatus: String, CaseIterable, Identifiable {
    case later, next, mainQuest, done
    var id: String { rawValue }
    var title: String {
        switch self {
        case .later: "Later"
        case .next: "Next"
        case .mainQuest: "Main Quest"
        case .done: "Done"
        }
    }
}

enum InputKind: String, CaseIterable, Identifiable {
    case caffeine, nicotine, medication, meal, water, nap, exercise, custom
    case breakTime = "break"
    var id: String { rawValue }
    var title: String { self == .breakTime ? "Break" : rawValue.capitalized }
}

@Model final class TaskItem {
    var id: UUID = UUID()
    var title: String
    var notes: String?
    var importance: Int?
    var urgency: Int?
    var effortEstimate: Int?
    var durationEstimateMinutes: Int?
    var statusRaw: String = TaskStatus.next.rawValue
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var completedAt: Date?
    @Relationship(deleteRule: .nullify, inverse: \Tag.tasks) var tags: [Tag] = []

    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .later }
        set {
            statusRaw = newValue.rawValue
            updatedAt = Date()
            completedAt = newValue == .done ? Date() : nil
        }
    }

    init(title: String, status: TaskStatus = .next) {
        self.title = title
        self.statusRaw = status.rawValue
    }
}

@Model final class FocusSession {
    var id: UUID = UUID()
    @Relationship(deleteRule: .nullify) var task: TaskItem?
    var plannedDurationMinutes: Int
    var actualDurationSeconds: TimeInterval = 0
    var isStarted: Bool = false
    var isCompleted: Bool = false
    var isPaused: Bool = false
    var startedAt: Date?
    var endedAt: Date?
    var resumedAt: Date?
    var preFocus: Int?
    var preEnergy: Int?
    var preMood: Int?
    var preDifficulty: Int?
    var postFocus: Int?
    var postEnergy: Int?
    var postMood: Int?
    var postDifficulty: Int?

    init(task: TaskItem?, plannedDurationMinutes: Int) {
        self.task = task
        self.plannedDurationMinutes = plannedDurationMinutes
    }

    func elapsed(at date: Date = Date()) -> TimeInterval {
        actualDurationSeconds + (resumedAt.map { max(0, date.timeIntervalSince($0)) } ?? 0)
    }

    func start(at date: Date = Date()) {
        guard !isStarted else { return }
        isStarted = true
        isPaused = false
        startedAt = date
        resumedAt = date
    }

    func pause(at date: Date = Date()) {
        guard isStarted, !isCompleted, let resumedAt else { return }
        actualDurationSeconds += max(0, date.timeIntervalSince(resumedAt))
        self.resumedAt = nil
        isPaused = true
    }

    func resume(at date: Date = Date()) {
        guard isStarted, !isCompleted, isPaused else { return }
        resumedAt = date
        isPaused = false
    }

    func complete(at date: Date = Date()) {
        guard isStarted, !isCompleted else { return }
        pause(at: date)
        isCompleted = true
        endedAt = date
    }
}

@Model final class CheckIn {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var focus: Int?
    var energy: Int?
    var mood: Int?
    var difficulty: Int?
    init(timestamp: Date = Date()) { self.timestamp = timestamp }
}

@Model final class InputLog {
    var id: UUID = UUID()
    var typeRaw: String
    var textValue: String?
    var numericValue: Double?
    var timestamp: Date = Date()
    var type: InputKind {
        get { InputKind(rawValue: typeRaw) ?? .custom }
        set { typeRaw = newValue.rawValue }
    }
    init(type: InputKind, textValue: String? = nil, numericValue: Double? = nil, timestamp: Date = Date()) {
        self.typeRaw = type.rawValue
        self.textValue = textValue
        self.numericValue = numericValue
        self.timestamp = timestamp
    }
}

@Model final class DailyGoal {
    var id: UUID = UUID()
    var date: Date
    @Relationship(deleteRule: .nullify) var outcomes: [TaskItem] = []
    init(date: Date) { self.date = Calendar.current.startOfDay(for: date) }
}

@Model final class Tag {
    var id: UUID = UUID()
    var label: String
    var tasks: [TaskItem] = []
    init(label: String) { self.label = label }
}
