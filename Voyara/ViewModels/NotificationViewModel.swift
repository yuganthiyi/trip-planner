import Combine
import SwiftUI
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

class NotificationViewModel: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var notifications: [AppNotification] = []
    @Published var showBanner = false
    @Published var bannerNotification: AppNotification?
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var userId: String?
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
        
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if let user = user {
                self.userId = user.uid
                self.fetchNotifications()
                self.scheduleTripReminders()
            } else {
                self.userId = nil
                self.notifications = []
                self.listenerRegistration?.remove()
            }
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    // MARK: - Permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            print("Notification permission granted: \(granted)")
        }
    }
    
    // MARK: - Fetch from Firebase
    private func fetchNotifications() {
        guard let uid = userId else { return }
        
        listenerRegistration?.remove()
        listenerRegistration = db.collection("users").document(uid).collection("notifications")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                
                let fetched = documents.compactMap { doc -> AppNotification? in
                    guard let data = try? JSONSerialization.data(withJSONObject: doc.data()) else { return nil }
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .millisecondsSince1970
                    return try? decoder.decode(AppNotification.self, from: data)
                }
                
                DispatchQueue.main.async {
                    let oldCount = self?.notifications.count ?? 0
                    self?.notifications = fetched
                    
                    // If empty, generate some initial welcoming notifications
                    if fetched.isEmpty {
                        self?.generateInitialNotifications()
                    }
                    
                    // Show banner for any new notifications
                    if fetched.count > oldCount, let newest = fetched.first, !newest.isRead {
                        self?.showInAppBanner(newest)
                    }
                }
            }
    }
    
    // MARK: - Initial Notifications
    private func generateInitialNotifications() {
        guard let uid = userId else { return }
        
        let initialNotifications = [
            AppNotification(id: UUID().uuidString, title: "Welcome to Voyara!", message: "Start planning your dream trip today.", type: .general, isRead: false, timestamp: Date()),
            AppNotification(id: UUID().uuidString, title: "Profile Complete", message: "Your profile setup is complete. Add a profile picture to personalize your account.", type: .general, isRead: false, timestamp: Date().addingTimeInterval(-3600))
        ]
        
        let batch = db.batch()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        
        for notif in initialNotifications {
            let docRef = db.collection("users").document(uid).collection("notifications").document(notif.id)
            if let data = try? encoder.encode(notif),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                batch.setData(dict, forDocument: docRef)
            }
        }
        
        batch.commit()
        
        // Also push the welcome notification as a real system notification
        pushLocalNotification(title: "Welcome to Voyara! 🌍", body: "Start planning your dream trip today.", identifier: "welcome")
    }
    
    // MARK: - Push Local Notification
    func pushLocalNotification(title: String, body: String, identifier: String, delay: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: unreadCount + 1)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Trip Reminders
    func scheduleTripReminders() {
        // Clear old scheduled notifications first
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule reminders for upcoming trips (fetched via Firestore)
        guard let uid = userId else { return }
        
        db.collection("users").document(uid).collection("trips").getDocuments { [weak self] snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            for doc in documents {
                guard let data = try? JSONSerialization.data(withJSONObject: doc.data()),
                      let trip = try? JSONDecoder().decode(Trip.self, from: data) else { continue }
                
                // Schedule a reminder 1 day before the trip
                let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: trip.startDate) ?? trip.startDate
                if reminderDate > Date() {
                    self?.scheduleNotification(
                        title: "Trip Tomorrow! ✈️",
                        body: "Your trip \"\(trip.title)\" to \(trip.destination) starts tomorrow. Make sure everything is packed!",
                        date: reminderDate,
                        identifier: "trip_reminder_\(trip.id)"
                    )
                }
                
                // Schedule a packing reminder 3 days before
                let packingDate = Calendar.current.date(byAdding: .day, value: -3, to: trip.startDate) ?? trip.startDate
                if packingDate > Date() {
                    self?.scheduleNotification(
                        title: "Time to Pack! 🧳",
                        body: "Your trip \"\(trip.title)\" is in 3 days. Start packing your essentials!",
                        date: packingDate,
                        identifier: "packing_reminder_\(trip.id)"
                    )
                }
            }
        }
    }
    
    private func scheduleNotification(title: String, body: String, date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Add & Push Notification
    func addNotification(title: String, message: String, type: NotificationType, tripId: String? = nil) {
        guard let uid = userId else { return }
        
        let notif = AppNotification(
            id: UUID().uuidString, title: title, message: message,
            type: type, isRead: false, timestamp: Date(), tripId: tripId
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        
        if let data = try? encoder.encode(notif),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            db.collection("users").document(uid).collection("notifications").document(notif.id).setData(dict)
        }
        
        // Also push it as a real system notification
        pushLocalNotification(title: title, body: message, identifier: notif.id)
    }
    
    // MARK: - In-App Banner
    func showInAppBanner(_ notification: AppNotification) {
        bannerNotification = notification
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showBanner = true
        }
        
        // Auto-dismiss after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.showBanner = false
            }
        }
    }
    
    // MARK: - Actions
    func markAsRead(_ notification: AppNotification) {
        guard let uid = userId else { return }
        
        var updated = notification
        updated.isRead = true
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        
        if let data = try? encoder.encode(updated),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            db.collection("users").document(uid).collection("notifications").document(updated.id).setData(dict, merge: true)
        }
        
        // Update badge count
        UNUserNotificationCenter.current().setBadgeCount(max(0, unreadCount - 1))
    }
    
    func markAllAsRead() {
        guard let uid = userId else { return }
        let batch = db.batch()
        
        for notif in notifications where !notif.isRead {
            let docRef = db.collection("users").document(uid).collection("notifications").document(notif.id)
            batch.updateData(["isRead": true], forDocument: docRef)
        }
        
        batch.commit()
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    func deleteNotification(_ notification: AppNotification) {
        guard let uid = userId else { return }
        db.collection("users").document(uid).collection("notifications").document(notification.id).delete()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    // Show notification as popup even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Could navigate to specific screen based on notification
        completionHandler()
    }
}

