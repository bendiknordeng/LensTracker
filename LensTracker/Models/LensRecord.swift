import Foundation
import SwiftData

@Model
final class LensRecord {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var lensTypeName: String
    var replacementDays: Int
    var isActive: Bool

    init(
        startDate: Date = .now,
        lensTypeName: String = "Monthly",
        replacementDays: Int = 30,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.startDate = startDate
        self.lensTypeName = lensTypeName
        self.replacementDays = replacementDays
        self.isActive = isActive
    }

    var dueDate: Date {
        Calendar.current.date(byAdding: .day, value: replacementDays, to: startDate) ?? startDate
    }

    var daysElapsed: Int {
        daysElapsed(at: .now)
    }

    func daysElapsed(at date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: startDate, to: date).day ?? 0
    }

    var daysRemaining: Int {
        daysRemaining(at: .now)
    }

    func daysRemaining(at date: Date) -> Int {
        max(0, replacementDays - daysElapsed(at: date))
    }

    var progress: Double {
        progress(at: .now)
    }

    func progress(at date: Date) -> Double {
        guard replacementDays > 0 else { return 1.0 }
        return min(1.0, Double(daysElapsed(at: date)) / Double(replacementDays))
    }

    var isOverdue: Bool {
        isOverdue(at: .now)
    }

    func isOverdue(at date: Date) -> Bool {
        daysRemaining(at: date) == 0 && isActive
    }
}

enum LensType: String, CaseIterable {
    case daily = "Daily"
    case biweekly = "Bi-Weekly"
    case monthly = "Monthly"

    var defaultDays: Int {
        switch self {
        case .daily: return 1
        case .biweekly: return 14
        case .monthly: return 30
        }
    }
}
