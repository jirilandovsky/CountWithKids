import Foundation
import UserNotifications

// Weekly parent report (GUIDED_LEARNING_DEV_PLAN.md §2.4 + §4.1).
//
// Sunday 19:00 local-time local notification → in-app card with 3 sentences
// + a stacked bar chart of weekly clean sheets per operation.
//
// Permission requested on first guided-session completion (NOT at app launch).
// First notification is suppressed until the kid has ≥ 3 guided sessions to
// avoid empty reports.
@MainActor
enum WeeklyReportService {
    static let notificationIdentifier = "guided.weekly.report"
    static let permissionAskedKey = "guided.notificationPermissionAsked"
    static let guidedSessionCountKey = "guided.sessionCount"

    /// Total guided session threshold before we'll schedule the first notification.
    static let minimumGuidedSessionsBeforeFirstReport = 3

    /// Increments the guided-only counter (free-practice sessions don't bump it)
    /// and returns the new value.
    @discardableResult
    static func incrementGuidedSessionCount() -> Int {
        let next = UserDefaults.standard.integer(forKey: guidedSessionCountKey) + 1
        UserDefaults.standard.set(next, forKey: guidedSessionCountKey)
        return next
    }

    /// Call once after a guided session completes. On the first call this
    /// requests notification permission; on subsequent calls it (re)schedules
    /// the next Sunday 19:00 notification when the threshold is met.
    static func didCompleteGuidedSession(totalGuidedSessions: Int) async {
        let center = UNUserNotificationCenter.current()
        let asked = UserDefaults.standard.bool(forKey: permissionAskedKey)
        if !asked {
            UserDefaults.standard.set(true, forKey: permissionAskedKey)
            do {
                _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            } catch {
                print("[WeeklyReportService] notification auth failed: \(error)")
                return
            }
        }
        guard totalGuidedSessions >= minimumGuidedSessionsBeforeFirstReport else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }
        scheduleNextSundayEvening()
    }

    /// Replaces any existing scheduled report notification with one fired at
    /// 19:00 the next upcoming Sunday (local time).
    static func scheduleNextSundayEvening(now: Date = Date(), calendar: Calendar = .current) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])

        guard let target = nextSundayAt19(after: now, calendar: calendar) else { return }
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: target)

        let content = UNMutableNotificationContent()
        content.title = loc("Weekly report")
        content.body = loc("This week's progress is ready. Tap to see how your child is doing.")
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                print("[WeeklyReportService] failed to schedule: \(error)")
            }
        }
    }

    static func nextSundayAt19(after date: Date, calendar: Calendar = .current) -> Date? {
        var components = DateComponents()
        components.weekday = 1 // Sunday in Gregorian
        components.hour = 19
        components.minute = 0
        return calendar.nextDate(
            after: date,
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents
        )
    }

    // MARK: - Report data

    struct Summary: Equatable {
        struct OperationStat: Equatable {
            let operation: MathOperation
            let cleanSheets: Int
        }

        /// e.g., "Tento týden Anna zvládla 12 čistých sérií. Nejvíc se zlepšila v odčítání. Teď pracuje na násobení."
        let stats: [OperationStat]
        let totalCleanSheets: Int
        let strongestOperation: MathOperation?
        let nextFocusOperation: MathOperation?
    }

    /// Pure function: compute weekly summary from sessions + mastery rows.
    static func summary(
        sessions: [PracticeSession],
        progress: [MasteryProgress],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Summary {
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let weekly = sessions.filter { $0.completedAt >= weekAgo && $0.isCleanSheet }

        // Per-op clean-sheet count, derived from the session's primary operation
        // (denormalized on PracticeSession). Single-op sessions dominate; mixed
        // sessions get split across ops they include.
        var counts: [MathOperation: Int] = [:]
        for session in weekly {
            let ops = session.operationsRaw.compactMap { MathOperation(rawValue: $0) }
            guard !ops.isEmpty else { continue }
            for op in ops {
                counts[op, default: 0] += 1
            }
        }

        let stats = MathOperation.allCases.map { op in
            Summary.OperationStat(operation: op, cleanSheets: counts[op] ?? 0)
        }

        let strongest = counts.max(by: { $0.value < $1.value })?.key
        let nextFocus = progress.min(by: { $0.level < $1.level })?.operation

        return Summary(
            stats: stats,
            totalCleanSheets: weekly.count,
            strongestOperation: strongest,
            nextFocusOperation: nextFocus
        )
    }
}
