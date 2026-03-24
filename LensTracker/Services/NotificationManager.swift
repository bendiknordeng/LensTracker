import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var isAuthorized = false

    private init() {}

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            print("Notification authorization error: \(error)")
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func scheduleLensReminder(dueDate: Date, daysBeforeReminder: Int = 1) {
        removeAllPending()

        // Day-before reminder
        if daysBeforeReminder > 0,
           let reminderDate = Calendar.current.date(byAdding: .day, value: -daysBeforeReminder, to: dueDate),
           reminderDate > .now {
            let content = UNMutableNotificationContent()
            content.title = "Lens Change Coming Up"
            content.body = "Your contact lenses should be replaced in \(daysBeforeReminder) day\(daysBeforeReminder > 1 ? "s" : "")."
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "lens-reminder-before", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }

        // Due date notification
        if dueDate > .now {
            let content = UNMutableNotificationContent()
            content.title = "Time to Change Lenses!"
            content.body = "Your contact lenses should be replaced today."
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: dueDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "lens-reminder-due", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }

        // Overdue reminder (1 day after)
        if let overdueDate = Calendar.current.date(byAdding: .day, value: 1, to: dueDate),
           overdueDate > .now {
            let content = UNMutableNotificationContent()
            content.title = "Lenses Overdue!"
            content.body = "Your contact lenses are past their replacement date. Please change them soon."
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: overdueDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "lens-reminder-overdue", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    func removeAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
