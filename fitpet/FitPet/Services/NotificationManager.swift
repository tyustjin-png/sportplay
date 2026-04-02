import UserNotifications
import Foundation

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermissionAndSchedule(hour: Int = 20, minute: Int = 0) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            self.scheduleDailyReminder(hour: hour, minute: minute)
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["fitpet.daily"])

        let content = UNMutableNotificationContent()
        content.title = "FitPet"
        content.body  = "该去运动了，小龙在等你 🐉"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour   = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "fitpet.daily", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
