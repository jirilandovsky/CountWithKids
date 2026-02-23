import Foundation

enum TimeFrame: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .day: return "timeframe.day"
        case .week: return "timeframe.week"
        case .month: return "timeframe.month"
        case .year: return "timeframe.year"
        }
    }
}

struct ChartBucket: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct AggregatedMetrics {
    let averageErrors: Double
    let averageTime: Double
    let cleanSheetCount: Int
    let totalSessions: Int
    let errorChartData: [ChartBucket]
    let timeChartData: [ChartBucket]
    let cleanSheetChartData: [ChartBucket]

    static let empty = AggregatedMetrics(
        averageErrors: 0, averageTime: 0, cleanSheetCount: 0, totalSessions: 0,
        errorChartData: [], timeChartData: [], cleanSheetChartData: []
    )
}

struct DashboardAggregator {
    static func aggregate(
        sessions: [PracticeSession],
        difficultyKey: String,
        timeFrame: TimeFrame
    ) -> AggregatedMetrics {
        let startDate = self.startDate(for: timeFrame)
        let filtered = sessions.filter {
            $0.difficultyKey == difficultyKey && $0.completedAt >= startDate
        }

        guard !filtered.isEmpty else { return .empty }

        let avgErrors = Double(filtered.map(\.errorCount).reduce(0, +)) / Double(filtered.count)
        let avgTime = filtered.map(\.durationSeconds).reduce(0, +) / Double(filtered.count)
        let cleanSheets = filtered.filter(\.isCleanSheet).count

        let errorBuckets = bucketize(filtered, timeFrame: timeFrame) { sessions in
            guard !sessions.isEmpty else { return 0 }
            return Double(sessions.map(\.errorCount).reduce(0, +)) / Double(sessions.count)
        }

        let timeBuckets = bucketize(filtered, timeFrame: timeFrame) { sessions in
            guard !sessions.isEmpty else { return 0 }
            return sessions.map(\.durationSeconds).reduce(0, +) / Double(sessions.count)
        }

        let cleanSheetBuckets = bucketize(filtered, timeFrame: timeFrame) { sessions in
            Double(sessions.filter(\.isCleanSheet).count)
        }

        return AggregatedMetrics(
            averageErrors: avgErrors,
            averageTime: avgTime,
            cleanSheetCount: cleanSheets,
            totalSessions: filtered.count,
            errorChartData: errorBuckets,
            timeChartData: timeBuckets,
            cleanSheetChartData: cleanSheetBuckets
        )
    }

    private static func startDate(for timeFrame: TimeFrame) -> Date {
        let now = Date()
        switch timeFrame {
        case .day: return now.startOfDay
        case .week: return now.daysAgo(7)
        case .month: return now.monthsAgo(1)
        case .year: return now.startOfYear
        }
    }

    private static func bucketize(
        _ sessions: [PracticeSession],
        timeFrame: TimeFrame,
        valueExtractor: ([PracticeSession]) -> Double
    ) -> [ChartBucket] {
        let calendar = Calendar.current

        switch timeFrame {
        case .day:
            // Bucket by 4-hour blocks
            var buckets: [(String, [PracticeSession])] = []
            let labels = ["0-4", "4-8", "8-12", "12-16", "16-20", "20-24"]
            for i in 0..<6 {
                let hourStart = i * 4
                let hourEnd = hourStart + 4
                let sessionsInBucket = sessions.filter { session in
                    let hour = calendar.component(.hour, from: session.completedAt)
                    return hour >= hourStart && hour < hourEnd
                }
                buckets.append((labels[i], sessionsInBucket))
            }
            return buckets.map { ChartBucket(label: $0.0, value: valueExtractor($0.1)) }

        case .week:
            // Bucket by day of week
            var buckets: [(String, [PracticeSession])] = []
            for i in 0..<7 {
                let targetDate = Date().daysAgo(6 - i)
                let dayStart = calendar.startOfDay(for: targetDate)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                let sessionsInBucket = sessions.filter {
                    $0.completedAt >= dayStart && $0.completedAt < dayEnd
                }
                buckets.append((targetDate.shortDayName, sessionsInBucket))
            }
            return buckets.map { ChartBucket(label: $0.0, value: valueExtractor($0.1)) }

        case .month:
            // Bucket by week
            var buckets: [(String, [PracticeSession])] = []
            for i in 0..<4 {
                let weekStart = Date().daysAgo((3 - i) * 7)
                let weekEnd = Date().daysAgo(max(0, (2 - i) * 7))
                let sessionsInBucket = sessions.filter {
                    $0.completedAt >= weekStart && $0.completedAt < weekEnd
                }
                buckets.append(("W\(i + 1)", sessionsInBucket))
            }
            return buckets.map { ChartBucket(label: $0.0, value: valueExtractor($0.1)) }

        case .year:
            // Bucket by month
            var buckets: [(String, [PracticeSession])] = []
            for i in 0..<12 {
                let monthStart = Date().monthsAgo(11 - i)
                let monthEnd = Date().monthsAgo(max(0, 10 - i))
                let sessionsInBucket = sessions.filter {
                    $0.completedAt >= monthStart.startOfMonth && $0.completedAt < monthEnd.startOfMonth
                }
                buckets.append((monthStart.shortMonthName, sessionsInBucket))
            }
            return buckets.map { ChartBucket(label: $0.0, value: valueExtractor($0.1)) }
        }
    }

    static func availableDifficultyKeys(from sessions: [PracticeSession]) -> [String] {
        Array(Set(sessions.map(\.difficultyKey))).sorted()
    }

    static func displayName(for difficultyKey: String) -> String {
        let parts = difficultyKey.split(separator: "_")
        guard parts.count >= 3 else { return difficultyKey }
        let range = parts[0]
        let ops = String(parts[1]).map { String($0) }.joined(separator: " ")
        let count = parts[2]
        return "To \(range), \(ops), \(count)/page"
    }
}
