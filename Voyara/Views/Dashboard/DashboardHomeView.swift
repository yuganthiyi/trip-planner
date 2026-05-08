import SwiftUI

// MARK: - Dashboard Home View
struct DashboardHomeView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    @Binding var selectedTab: Int
    @State private var showNotifications = false
    @State private var showWeatherDetail = false
    @State private var showMapView = false
    @State private var searchText = ""
    @State private var animateCards = false
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: VoyaraTheme.spacing24) {
                        // Header
                        headerSection
                        
                        // Search Bar
                        searchBar
                        
                        // Weather Widget
                        weatherWidget
                        
                        // Quick Stats
                        quickStatsSection
                        
                        // Quick Actions
                        quickActionsSection
                        
                        // Upcoming Trips
                        upcomingTripsSection
                        
                        // Trip Progress (ongoing)
                        ongoingTripsSection
                        
                        // Categories
                        categoriesSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, VoyaraTheme.spacing32)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNotifications) {
                NotificationsView()
            }
            .sheet(isPresented: $showWeatherDetail) {
                WeatherSuggestionsView()
            }
            .fullScreenCover(isPresented: $showMapView) {
                NavigationStack {
                    MapView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Close") { showMapView = false }
                                    .foregroundColor(VoyaraColors.primary)
                            }
                        }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    animateCards = true
                }
                weatherViewModel.refreshWeather()
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                Text(greeting)
                    .font(VoyaraTypography.bodyMedium)
                    .foregroundColor(VoyaraColors.textSecondary)
                Text("Where to next?")
                    .font(VoyaraTypography.displayLarge)
                    .foregroundColor(VoyaraColors.text)
            }
            
            Spacer()
            
            Button(action: { showNotifications = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(VoyaraColors.text)
                        .frame(width: 44, height: 44)
                        .background(VoyaraColors.surfaceVariant)
                        .cornerRadius(VoyaraTheme.mediumRadius)
                    
                    if notificationViewModel.unreadCount > 0 {
                        Circle()
                            .fill(VoyaraColors.error)
                            .frame(width: 10, height: 10)
                            .offset(x: 2, y: -2)
                    }
                }
            }
        }
        .padding(.horizontal, VoyaraTheme.spacing24)
        .padding(.top, VoyaraTheme.spacing16)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: VoyaraTheme.spacing12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(VoyaraColors.textSecondary)
            
            TextField("Search destinations, trips...", text: $searchText)
                .font(VoyaraTypography.bodyMedium)
                .foregroundColor(VoyaraColors.text)
                .onSubmit {
                    if !searchText.isEmpty {
                        // Search on map
                        showMapView = true
                    }
                }
        }
        .padding(VoyaraTheme.spacing12)
        .background(VoyaraColors.surfaceVariant)
        .cornerRadius(VoyaraTheme.mediumRadius)
        .padding(.horizontal, VoyaraTheme.spacing24)
    }
    
    // MARK: - Weather Widget
    private var weatherWidget: some View {
        Button(action: { showWeatherDetail = true }) {
            HStack(spacing: VoyaraTheme.spacing16) {
                if weatherViewModel.isLoading {
                    HStack(spacing: VoyaraTheme.spacing8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Fetching weather...")
                            .font(VoyaraTypography.bodyMedium)
                            .foregroundColor(VoyaraColors.textSecondary)
                    }
                    Spacer()
                } else if let weather = weatherViewModel.currentWeather {
                    VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                        HStack(spacing: VoyaraTheme.spacing8) {
                            Image(systemName: weather.conditionIcon)
                                .font(.system(size: 24))
                                .foregroundColor(weather.conditionColor)
                            
                            Text("\(Int(weather.temperature))°C")
                                .font(VoyaraTypography.displayMedium)
                                .foregroundColor(VoyaraColors.text)
                        }
                        
                        Text("\(weather.condition) • \(weatherViewModel.locationName)")
                            .font(VoyaraTypography.bodySmall)
                            .foregroundColor(VoyaraColors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: VoyaraTheme.spacing4) {
                        Text("Feels like \(Int(weather.feelsLike))°")
                            .font(VoyaraTypography.labelSmall)
                            .foregroundColor(VoyaraColors.textSecondary)
                        
                        HStack(spacing: VoyaraTheme.spacing8) {
                            Label("\(Int(weather.humidity))%", systemImage: "drop.fill")
                            Label("\(Int(weather.windSpeed)) km/h", systemImage: "wind")
                        }
                        .font(VoyaraTypography.captionSmall)
                        .foregroundColor(VoyaraColors.textSecondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(VoyaraColors.textSecondary)
                } else if let error = weatherViewModel.errorMessage {
                    HStack(spacing: VoyaraTheme.spacing8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(VoyaraColors.warning)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weather Unavailable")
                                .font(VoyaraTypography.bodyMedium)
                                .foregroundColor(VoyaraColors.text)
                            Text(error)
                                .font(VoyaraTypography.captionSmall)
                                .foregroundColor(VoyaraColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                } else {
                    HStack(spacing: VoyaraTheme.spacing8) {
                        Image(systemName: "cloud.sun.fill")
                            .font(.system(size: 24))
                            .foregroundColor(VoyaraColors.warning)
                        Text("Loading weather...")
                            .font(VoyaraTypography.bodyMedium)
                            .foregroundColor(VoyaraColors.textSecondary)
                    }
                    Spacer()
                }
            }
            .padding(VoyaraTheme.spacing16)
            .background(
                RoundedRectangle(cornerRadius: VoyaraTheme.cornerRadius)
                    .fill(VoyaraColors.surface)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, VoyaraTheme.spacing24)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }
    
    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        HStack(spacing: VoyaraTheme.spacing12) {
            StatCard(
                icon: "airplane",
                value: "\(tripViewModel.trips.count)",
                label: "Trips",
                color: VoyaraColors.primary
            )
            
            StatCard(
                icon: "mappin.circle.fill",
                value: "\(Set(tripViewModel.trips.map { $0.destination }).count)",
                label: "Places",
                color: VoyaraColors.accent
            )
            
            StatCard(
                icon: "checkmark.circle.fill",
                value: "\(tripViewModel.trips.filter { $0.status == .completed }.count)",
                label: "Done",
                color: VoyaraColors.success
            )
        }
        .padding(.horizontal, VoyaraTheme.spacing24)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 30)
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
            SectionHeader(title: "Quick Actions")
                .padding(.horizontal, VoyaraTheme.spacing24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: VoyaraTheme.spacing12) {
                    QuickActionCard(icon: "plus.circle.fill", title: "New Trip", color: VoyaraColors.primary) {
                        selectedTab = 1
                    }
                    QuickActionCard(icon: "map.fill", title: "Map", color: VoyaraColors.accent) {
                        showMapView = true
                    }
                    QuickActionCard(icon: "creditcard.fill", title: "Budget", color: VoyaraColors.secondary) {
                        selectedTab = 2
                    }
                    QuickActionCard(icon: "bag.fill", title: "Packing", color: VoyaraColors.categoryShopping) {
                        selectedTab = 3
                    }
                    QuickActionCard(icon: "cloud.sun.fill", title: "Weather", color: VoyaraColors.warning) {
                        showWeatherDetail = true
                    }
                }
                .padding(.horizontal, VoyaraTheme.spacing24)
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 40)
    }
    
    // MARK: - Upcoming Trips
    private var upcomingTripsSection: some View {
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
            SectionHeader(title: "Upcoming Trips", actionTitle: "See All") {
                selectedTab = 1
            }
            .padding(.horizontal, VoyaraTheme.spacing24)
            
            if tripViewModel.upcomingTrips.isEmpty {
                VoyaraCard {
                    VStack(spacing: VoyaraTheme.spacing12) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 32))
                            .foregroundColor(VoyaraColors.primary.opacity(0.5))
                        Text("No upcoming trips")
                            .font(VoyaraTypography.bodyMedium)
                            .foregroundColor(VoyaraColors.textSecondary)
                        Text("Tap + to plan your next adventure")
                            .font(VoyaraTypography.bodySmall)
                            .foregroundColor(VoyaraColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(VoyaraTheme.spacing16)
                }
                .padding(.horizontal, VoyaraTheme.spacing24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: VoyaraTheme.spacing16) {
                        ForEach(tripViewModel.upcomingTrips.prefix(5)) { trip in
                            NavigationLink(destination: TripDetailView(trip: trip)) {
                                UpcomingTripCard(trip: trip)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, VoyaraTheme.spacing24)
                }
            }
        }
    }
    
    // MARK: - Ongoing Trips Progress
    private var ongoingTripsSection: some View {
        Group {
            if !tripViewModel.ongoingTrips.isEmpty {
                VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
                    SectionHeader(title: "Trip Progress")
                        .padding(.horizontal, VoyaraTheme.spacing24)
                    
                    ForEach(tripViewModel.ongoingTrips) { trip in
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            TripProgressCard(trip: trip)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, VoyaraTheme.spacing24)
                    }
                }
            }
        }
    }
    
    // MARK: - Categories (Now tappable with Firebase data)
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
            SectionHeader(title: "Explore Categories")
                .padding(.horizontal, VoyaraTheme.spacing24)
            
            if categoryViewModel.categories.isEmpty {
                // Fallback while loading from Firebase
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: VoyaraTheme.spacing12) {
                    CategoryCardPlaceholder(icon: "mountain.2.fill", title: "Adventure", color: VoyaraColors.success)
                    CategoryCardPlaceholder(icon: "building.2.fill", title: "City Break", color: VoyaraColors.primary)
                    CategoryCardPlaceholder(icon: "sun.max.fill", title: "Beach", color: VoyaraColors.warning)
                    CategoryCardPlaceholder(icon: "fork.knife", title: "Food Tour", color: VoyaraColors.secondary)
                }
                .padding(.horizontal, VoyaraTheme.spacing24)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: VoyaraTheme.spacing12) {
                    ForEach(categoryViewModel.categories) { category in
                        NavigationLink(destination: CategoryExploreView(category: category)) {
                            CategoryCard(
                                icon: category.icon,
                                title: category.title,
                                count: category.destinationCount,
                                color: category.color
                            )
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, VoyaraTheme.spacing24)
            }
        }
    }
}
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: VoyaraTheme.spacing8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(VoyaraTypography.headlineLarge)
                .foregroundColor(VoyaraColors.text)
            
            Text(label)
                .font(VoyaraTypography.captionSmall)
                .foregroundColor(VoyaraColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(VoyaraTheme.spacing16)
        .background(VoyaraColors.surface)
        .cornerRadius(VoyaraTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: VoyaraTheme.spacing8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .cornerRadius(VoyaraTheme.mediumRadius)
                
                Text(title)
                    .font(VoyaraTypography.labelSmall)
                    .foregroundColor(VoyaraColors.text)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Upcoming Trip Card
struct UpcomingTripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
            // Destination Icon
            ZStack {
                RoundedRectangle(cornerRadius: VoyaraTheme.mediumRadius)
                    .fill(
                        LinearGradient(
                            colors: [VoyaraColors.primary, VoyaraColors.primaryDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 100)
                
                VStack(spacing: VoyaraTheme.spacing8) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(trip.destination.components(separatedBy: ",").first ?? trip.destination)
                        .font(VoyaraTypography.labelSmall)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                Text(trip.title)
                    .font(VoyaraTypography.headlineSmall)
                    .foregroundColor(VoyaraColors.text)
                    .lineLimit(1)
                
                Text(trip.dateRangeString)
                    .font(VoyaraTypography.captionSmall)
                    .foregroundColor(VoyaraColors.textSecondary)
                
                HStack {
                    StatusBadge(status: trip.status)
                    Spacer()
                    Text("\(trip.durationDays)d")
                        .font(VoyaraTypography.captionSmall)
                        .foregroundColor(VoyaraColors.textSecondary)
                }
            }
        }
        .frame(width: 180)
        .padding(VoyaraTheme.spacing12)
        .background(VoyaraColors.surface)
        .cornerRadius(VoyaraTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Trip Progress Card
struct TripProgressCard: View {
    let trip: Trip
    @EnvironmentObject var tripViewModel: TripViewModel
    
    var body: some View {
        VoyaraCard {
            HStack(spacing: VoyaraTheme.spacing16) {
                CircularProgressView(
                    progress: tripViewModel.tripCompletionPercentage(trip) / 100,
                    lineWidth: 6,
                    size: 52,
                    color: VoyaraColors.success
                )
                .overlay(
                    Text("\(Int(tripViewModel.tripCompletionPercentage(trip)))%")
                        .font(VoyaraTypography.labelSmall)
                        .foregroundColor(VoyaraColors.text)
                )
                
                VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                    Text(trip.title)
                        .font(VoyaraTypography.headlineSmall)
                        .foregroundColor(VoyaraColors.text)
                    
                    Text(trip.destination)
                        .font(VoyaraTypography.bodySmall)
                        .foregroundColor(VoyaraColors.textSecondary)
                    
                    HStack(spacing: VoyaraTheme.spacing8) {
                        Label("Day \(dayOfTrip(trip))/\(trip.durationDays)", systemImage: "calendar")
                            .font(VoyaraTypography.captionSmall)
                            .foregroundColor(VoyaraColors.primary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(VoyaraColors.textSecondary)
            }
        }
    }
    
    private func dayOfTrip(_ trip: Trip) -> Int {
        let days = Calendar.current.dateComponents([.day], from: trip.startDate, to: Date()).day ?? 0
        return max(1, min(days + 1, trip.durationDays))
    }
}

// MARK: - Category Card (Tappable)
struct CategoryCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .cornerRadius(VoyaraTheme.mediumRadius)
            
            VStack(alignment: .leading, spacing: VoyaraTheme.spacing2) {
                Text(title)
                    .font(VoyaraTypography.headlineSmall)
                    .foregroundColor(VoyaraColors.text)
                
                Text("\(count) destinations")
                    .font(VoyaraTypography.captionSmall)
                    .foregroundColor(VoyaraColors.textSecondary)
            }
            
            // Explore indicator
            HStack(spacing: 4) {
                Text("Explore")
                    .font(VoyaraTypography.captionSmall)
                    .foregroundColor(color)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(VoyaraTheme.spacing16)
        .background(VoyaraColors.surface)
        .cornerRadius(VoyaraTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Category Card Placeholder (shown while loading)
struct CategoryCardPlaceholder: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .cornerRadius(VoyaraTheme.mediumRadius)
            
            VStack(alignment: .leading, spacing: VoyaraTheme.spacing2) {
                Text(title)
                    .font(VoyaraTypography.headlineSmall)
                    .foregroundColor(VoyaraColors.text)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(VoyaraColors.surfaceVariant)
                    .frame(width: 80, height: 10)
                    .shimmer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(VoyaraTheme.spacing16)
        .background(VoyaraColors.surface)
        .cornerRadius(VoyaraTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
