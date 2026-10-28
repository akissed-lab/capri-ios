import Foundation
import UserNotifications

extension Notification.Name {
    static let capriMissedTap = Notification.Name("capriMissedTap")
}

/// Локальные уведомления «заскучала»: без сервера, всё считается на телефоне.
final class Notifier: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()

    @Published private(set) var authorized = false

    private let idsKey = "capri_pending_notification_ids"
    private var pendingTap = false

    /// Забирает флаг «пришли по уведомлению» один раз, чтобы не задвоить реплику.
    func consumePendingTap() -> Bool {
        let value = pendingTap
        pendingTap = false
        return value
    }

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        refreshStatus()
    }

    func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let ok = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            DispatchQueue.main.async { self?.authorized = ok }
        }
    }

    func requestIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self else { return }
            if settings.authorizationStatus == .notDetermined {
                Task { _ = await self.request() }
            } else {
                DispatchQueue.main.async {
                    self.authorized = settings.authorizationStatus == .authorized
                        || settings.authorizationStatus == .provisional
                }
            }
        }
    }

    @discardableResult
    func request() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await MainActor.run { self.authorized = granted }
        return granted
    }

    /// Планирует «скучаю» на три дня вперёд. При каждом открытии приложения время перемешивается.
    func reschedule(name: String) {
        let center = UNUserNotificationCenter.current()
        let old = UserDefaults.standard.stringArray(forKey: idsKey) ?? []
        if !old.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: old)
            UserDefaults.standard.set([String](), forKey: idsKey)
        }
        guard Config.notificationsOn else { return }

        let perDay = Config.intensity < 0.45 ? 2 : (Config.intensity < 0.75 ? 3 : 5)
        let calendar = Calendar.current
        var ids: [String] = []

        for day in 1...3 {
            guard let base = calendar.date(byAdding: .day, value: day, to: Date()) else { continue }
            for index in 0..<perDay {
                var components = calendar.dateComponents([.year, .month, .day], from: base)
                components.hour = Int.random(in: 10...22)
                components.minute = Int.random(in: 0...59)

                let content = UNMutableNotificationContent()
                content.title = "Капри"
                content.body = Persona.missedLine(name: name)
                content.sound = .default
                content.threadIdentifier = "capri-miss"

                let identifier = "capri-miss-\(day)-\(index)-\(UUID().uuidString.prefix(6))"
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)) { _ in }
                ids.append(identifier)
            }
        }
        UserDefaults.standard.set(ids, forKey: idsKey)
    }

    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        let ids = UserDefaults.standard.stringArray(forKey: idsKey) ?? []
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeAllDeliveredNotifications()
        UserDefaults.standard.set([String](), forKey: idsKey)
    }

    /// Проверка прямо сейчас: уведомление придёт через 8 секунд.
    func testSoon(name: String) {
        let content = UNMutableNotificationContent()
        content.title = "Капри"
        content.body = Persona.missedLine(name: name)
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 8, repeats: false)
        let identifier = "capri-test-\(UUID().uuidString.prefix(6))"
        UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)) { _ in }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        DispatchQueue.main.async {
            self.pendingTap = true
            NotificationCenter.default.post(name: .capriMissedTap, object: nil)
        }
        completionHandler()
    }
}
