import Foundation

// Tracks which Daily Plan slots (Warmup / Focus / Challenge) have been
// completed today, and computes the consecutive-full-days streak.
//
// Backed by UserDefaults: a single `[String: [Int]]` map of
//   "yyyy-MM-dd" → [slot.rawValue.hash]
// Only the last ~30 days are retained to keep the dictionary bounded.
extension Notification.Name {
    /// Posted whenever a Daily Plan slot is marked complete, so observers
    /// (e.g. ContentView's tab badge) can refresh state that's read from
    /// UserDefaults rather than from observable storage.
    static let dailyPlanStateChanged = Notification.Name("dailyPlanStateChanged")
}

@MainActor
enum DailyPlanState {
    private static let storeKey = "guided.dailyPlan.completion"
    private static let retentionDays = 60
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func markCompleted(_ slot: DailyPlanBuilder.Slot, on date: Date = Date()) {
        var map = load()
        let key = dayKey(date)
        var slots = Set(map[key] ?? [])
        slots.insert(slot.rawValue)
        map[key] = Array(slots)
        prune(&map, today: date)
        save(map)
        NotificationCenter.default.post(name: .dailyPlanStateChanged, object: nil)
    }

    static func completedSlots(on date: Date = Date()) -> Set<DailyPlanBuilder.Slot> {
        let raw = load()[dayKey(date)] ?? []
        return Set(raw.compactMap { DailyPlanBuilder.Slot(rawValue: $0) })
    }

    static func isComplete(_ slot: DailyPlanBuilder.Slot, on date: Date = Date()) -> Bool {
        completedSlots(on: date).contains(slot)
    }

    static func allSlotsComplete(on date: Date = Date()) -> Bool {
        completedSlots(on: date).count >= DailyPlanBuilder.Slot.allCases.count
    }

    /// Consecutive days, counting back from `today`, where every slot was completed.
    static func fullDayStreak(today: Date = Date(), calendar: Calendar = .current) -> Int {
        var day = calendar.startOfDay(for: today)
        var streak = 0
        while allSlotsComplete(on: day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: storeKey)
    }

    // MARK: - Private

    private static func dayKey(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    private static func load() -> [String: [String]] {
        UserDefaults.standard.dictionary(forKey: storeKey) as? [String: [String]] ?? [:]
    }

    private static func save(_ map: [String: [String]]) {
        UserDefaults.standard.set(map, forKey: storeKey)
    }

    private static func prune(_ map: inout [String: [String]], today: Date) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: today) ?? today
        let cutoffKey = dayKey(cutoff)
        for key in map.keys where key < cutoffKey {
            map.removeValue(forKey: key)
        }
    }
}
