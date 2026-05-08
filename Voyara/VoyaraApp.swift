import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct VoyaraApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var tripViewModel = TripViewModel()
    @StateObject private var weatherViewModel = WeatherViewModel()
    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var notificationViewModel = NotificationViewModel()
    @StateObject private var categoryViewModel = CategoryViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        FirebaseApp.configure()
        
        // Enable Offline Persistence explicitly
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        Firestore.firestore().settings = settings
        
        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(tripViewModel)
                .environmentObject(weatherViewModel)
                .environmentObject(mapViewModel)
                .environmentObject(notificationViewModel)
                .environmentObject(categoryViewModel)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                if authViewModel.faceIDEnabled {
                    authViewModel.isUnlocked = false
                }
            }
        }
    }
}
