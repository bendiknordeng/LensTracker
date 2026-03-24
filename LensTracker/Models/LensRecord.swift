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
        Calendar.current.dateComponents([.day], from: startDate, to: .now).day ?? 0
    }

    var daysRemaining: Int {
        max(0, replacementDays - daysElapsed)
    }

    var progress: Double {
        guard replacementDays > 0 else { return 1.0 }
        return min(1.0, Double(daysElapsed) / Double(replacementDays))
    }

    var isOverdue: Bool {
        daysRemaining == 0 && isActive
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
