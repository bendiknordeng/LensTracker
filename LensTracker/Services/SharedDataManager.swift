import Foundation

/// Shares data between the main app and widget via App Groups UserDefaults.
struct SharedDataManager {
    static let appGroupID = "group.com.lenstrack.shared"
    static let suiteName = appGroupID

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Keys
    private enum Keys {
        static let startDate = "widget_startDate"
        static let replacementDays = "widget_replacementDays"
        static let lensType = "widget_lensType"
        static let isActive = "widget_isActive"
    }

    // MARK: - Write
    static func updateWidget(startDate: Date, replacementDays: Int, lensType: String, isActive: Bool) {
        let d = defaults
        d?.set(startDate.timeIntervalSince1970, forKey: Keys.startDate)
        d?.set(replacementDays, forKey: Keys.replacementDays)
        d?.set(lensType, forKey: Keys.lensType)
        d?.set(isActive, forKey: Keys.isActive)
    }

    static func clearWidget() {
        let d = defaults
        d?.removeObject(forKey: Keys.startDate)
        d?.removeObject(forKey: Keys.replacementDays)
        d?.removeObject(forKey: Keys.lensType)
        d?.removeObject(forKey: Keys.isActive)
    }

    // MARK: - Read
    static func widgetData() -> WidgetData? {
        guard let d = defaults,
              d.object(forKey: Keys.startDate) != nil else { return nil }
        let startInterval = d.double(forKey: Keys.startDate)
        let startDate = Date(timeIntervalSince1970: startInterval)
        let replacementDays = d.integer(forKey: Keys.replacementDays)
        let lensType = d.string(forKey: Keys.lensType) ?? "Monthly"
        let isActive = d.bool(forKey: Keys.isActive)
        return WidgetData(startDate: startDate, replacementDays: replacementDays, lensType: lensType, isActive: isActive)
    }
}

struct WidgetData {
    let startDate: Date
    let replacementDays: Int
    let lensType: String
    let isActive: Bool

    var dueDate: Date {
        Calendar.current.date(byAdding: .day, value: replacementDays, to: startDate) ?? startDate
    }

    var daysRemaining: Int {
        let elapsed = Calendar.current.dateComponents([.day], from: startDate, to: .now).day ?? 0
        return max(0, replacementDays - elapsed)
    }

    var progress: Double {
        guard replacementDays > 0 else { return 1.0 }
        let elapsed = Calendar.current.dateComponents([.day], from: startDate, to: .now).day ?? 0
        return min(1.0, Double(elapsed) / Double(replacementDays))
    }

    var isOverdue: Bool {
        daysRemaining == 0 && isActive
    }
}
