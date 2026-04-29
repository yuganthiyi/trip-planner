import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardHomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            TripsView()
                .tabItem {
                    Label("Trips", systemImage: "airplane")
                }
                .tag(1)
            
            BudgetTabView()
                .tabItem {
                    Label("Budget", systemImage: "creditcard.fill")
                }
                .tag(2)
            
            PackingListsView()
                .tabItem {
                    Label("Packing", systemImage: "bag.fill")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(VoyaraColors.primary)
    }
}