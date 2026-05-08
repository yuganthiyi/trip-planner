import SwiftUI
import MapKit

// MARK: - Category Explore View
struct CategoryExploreView: View {
    let category: ExploreCategory
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    @State private var selectedDestination: CategoryDestination?
    @State private var destinationWeather: [String: WeatherInfo] = [:]
    @State private var loadingWeather: Set<String> = []
    @State private var mapPosition: MapCameraPosition = .automatic
    
    var body: some View {
        ZStack {
            VoyaraColors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: VoyaraTheme.spacing24) {
                    // Hero Header
                    heroHeader
                    
                    // Map Overview
                    mapOverview
                    
                    // Destinations List
                    destinationsSection
                }
                .padding(.bottom, VoyaraTheme.spacing32)
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedDestination) { destination in
            DestinationDetailSheet(
                destination: destination,
                category: category,
                weather: destinationWeather[destination.id]
            )
        }
        .onAppear {
            fetchWeatherForDestinations()
        }
    }
    
    // MARK: - Hero Header
    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [category.color, category.color.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 160)
            
            VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
                Image(systemName: category.icon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("\(category.destinationCount) Destinations")
                    .font(VoyaraTypography.headlineSmall)
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Explore the best \(category.title.lowercased()) destinations with live weather data")
                    .font(VoyaraTypography.bodySmall)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            .padding(VoyaraTheme.spacing24)
        }
    }
    
    // MARK: - Map Overview
    private var mapOverview: some View {
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
            SectionHeader(title: "Map")
                .padding(.horizontal, VoyaraTheme.spacing24)
            
            Map(position: $mapPosition) {
                ForEach(category.destinations) { dest in
                    Annotation(dest.name, coordinate: CLLocationCoordinate2D(latitude: dest.latitude, longitude: dest.longitude)) {
                        Button(action: { selectedDestination = dest }) {
                            VStack(spacing: 2) {
                                ZStack {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 32, height: 32)
                                    
                                    // Show temperature if available
                                    if let weather = destinationWeather[dest.id] {
                                        Text("\(Int(weather.temperature))°")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .shadow(radius: 3)
                                
                                Text(dest.name)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(VoyaraColors.text)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 220)
            .cornerRadius(VoyaraTheme.cornerRadius)
            .padding(.horizontal, VoyaraTheme.spacing24)
        }
    }
    
    // MARK: - Destinations Section
    private var destinationsSection: some View {
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
            SectionHeader(title: "Destinations")
                .padding(.horizontal, VoyaraTheme.spacing24)
            
            ForEach(category.destinations) { destination in
                Button(action: { selectedDestination = destination }) {
                    destinationCard(destination)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .padding(.horizontal, VoyaraTheme.spacing24)
            }
        }
    }
    
    // MARK: - Destination Card
    private func destinationCard(_ destination: CategoryDestination) -> some View {
        VoyaraCard {
            VStack(spacing: VoyaraTheme.spacing12) {
                HStack(spacing: VoyaraTheme.spacing12) {
                    // Icon
                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(category.color)
                        .cornerRadius(VoyaraTheme.mediumRadius)
                    
                    // Info
                    VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                        Text(destination.name)
                            .font(VoyaraTypography.headlineSmall)
                            .foregroundColor(VoyaraColors.text)
                        
                        Text(destination.country)
                            .font(VoyaraTypography.bodySmall)
                            .foregroundColor(VoyaraColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Weather badge
                    if loadingWeather.contains(destination.id) {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if let weather = destinationWeather[destination.id] {
                        weatherBadge(weather)
                    }
                    
                    // Rating
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", destination.rating))
                            .font(VoyaraTypography.labelSmall)
                            .foregroundColor(VoyaraColors.text)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(VoyaraColors.textSecondary)
                }
                
                Text(destination.description)
                    .font(VoyaraTypography.bodySmall)
                    .foregroundColor(VoyaraColors.textSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Weather Badge
    private func weatherBadge(_ weather: WeatherInfo) -> some View {
        HStack(spacing: 4) {
            Image(systemName: weather.conditionIcon)
                .font(.system(size: 12))
                .foregroundColor(weather.conditionColor)
            Text("\(Int(weather.temperature))°")
                .font(VoyaraTypography.labelSmall)
                .foregroundColor(VoyaraColors.text)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(VoyaraColors.surfaceVariant)
        .cornerRadius(12)
    }
    
    // MARK: - Fetch Weather for All Destinations
    private func fetchWeatherForDestinations() {
        for destination in category.destinations {
            guard destinationWeather[destination.id] == nil else { continue }
            
            loadingWeather.insert(destination.id)
            
            Task {
                let location = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
                let result = await VoyaraWeatherService.shared.fetchWeather(for: location)
                
                await MainActor.run {
                    loadingWeather.remove(destination.id)
                    if let current = result?.current {
                        destinationWeather[destination.id] = current
                    }
                }
            }
        }
    }
}

// MARK: - Destination Detail Sheet
struct DestinationDetailSheet: View {
    let destination: CategoryDestination
    let category: ExploreCategory
    let weather: WeatherInfo?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripViewModel: TripViewModel
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    @State private var showTripSelector = false
    @State private var showCreateNewTrip = false
    @State private var weatherActivities: [WeatherActivity] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: VoyaraTheme.spacing24) {
                        // Header
                        ZStack(alignment: .bottomLeading) {
                            LinearGradient(
                                colors: [category.color, category.color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 180)
                            
                            VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
                                Text(destination.country)
                                    .font(VoyaraTypography.labelSmall)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(destination.name)
                                    .font(VoyaraTypography.displayLarge)
                                    .foregroundColor(.white)
                                
                                HStack(spacing: VoyaraTheme.spacing8) {
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", destination.rating))
                                            .foregroundColor(.white)
                                    }
                                    .font(VoyaraTypography.labelSmall)
                                    
                                    if let weather = weather {
                                        HStack(spacing: 4) {
                                            Image(systemName: weather.conditionIcon)
                                                .foregroundColor(weather.conditionColor)
                                            Text("\(Int(weather.temperature))°C")
                                                .foregroundColor(.white)
                                        }
                                        .font(VoyaraTypography.labelSmall)
                                    }
                                }
                            }
                            .padding(VoyaraTheme.spacing24)
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
                            Text("About")
                                .font(VoyaraTypography.headlineMedium)
                                .foregroundColor(VoyaraColors.text)
                            Text(destination.description)
                                .font(VoyaraTypography.bodyMedium)
                                .foregroundColor(VoyaraColors.textSecondary)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, VoyaraTheme.spacing24)
                        
                        // Weather Section
                        if let weather = weather {
                            VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
                                Text("Current Weather")
                                    .font(VoyaraTypography.headlineMedium)
                                    .foregroundColor(VoyaraColors.text)
                                
                                VoyaraCard {
                                    HStack(spacing: VoyaraTheme.spacing16) {
                                        Image(systemName: weather.conditionIcon)
                                            .font(.system(size: 36))
                                            .foregroundColor(weather.conditionColor)
                                        
                                        VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                                            Text("\(Int(weather.temperature))°C")
                                                .font(VoyaraTypography.displayMedium)
                                                .foregroundColor(VoyaraColors.text)
                                            Text(weather.condition)
                                                .font(VoyaraTypography.bodySmall)
                                                .foregroundColor(VoyaraColors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: VoyaraTheme.spacing4) {
                                            Label("\(Int(weather.humidity))%", systemImage: "drop.fill")
                                            Label("\(Int(weather.windSpeed)) km/h", systemImage: "wind")
                                        }
                                        .font(VoyaraTypography.captionSmall)
                                        .foregroundColor(VoyaraColors.textSecondary)
                                    }
                                }
                            }
                            .padding(.horizontal, VoyaraTheme.spacing24)
                        }
                        
                        // Weather-Based Activity Suggestions
                        if !weatherActivities.isEmpty {
                            VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
                                Text("Suggested Activities")
                                    .font(VoyaraTypography.headlineMedium)
                                    .foregroundColor(VoyaraColors.text)
                                
                                ForEach(weatherActivities) { activity in
                                    VoyaraCard {
                                        HStack(spacing: VoyaraTheme.spacing12) {
                                            Image(systemName: activity.icon)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.white)
                                                .frame(width: 40, height: 40)
                                                .background(activity.suitabilityColor)
                                                .cornerRadius(VoyaraTheme.mediumRadius)
                                            
                                            VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                                                HStack {
                                                    Text(activity.title)
                                                        .font(VoyaraTypography.bodyMedium)
                                                        .foregroundColor(VoyaraColors.text)
                                                    Spacer()
                                                    Text(activity.isOutdoor ? "Outdoor" : "Indoor")
                                                        .font(VoyaraTypography.captionSmall)
                                                        .foregroundColor(activity.isOutdoor ? VoyaraColors.success : VoyaraColors.primary)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(
                                                            (activity.isOutdoor ? VoyaraColors.success : VoyaraColors.primary).opacity(0.12)
                                                        )
                                                        .cornerRadius(8)
                                                }
                                                
                                                Text(activity.description)
                                                    .font(VoyaraTypography.bodySmall)
                                                    .foregroundColor(VoyaraColors.textSecondary)
                                                    .lineLimit(2)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, VoyaraTheme.spacing24)
                        }
                        
                        // Map
                        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
                            Text("Location")
                                .font(VoyaraTypography.headlineMedium)
                                .foregroundColor(VoyaraColors.text)
                            
                            Map {
                                Annotation(destination.name, coordinate: CLLocationCoordinate2D(latitude: destination.latitude, longitude: destination.longitude)) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(category.color)
                                        .cornerRadius(8)
                                        .shadow(radius: 3)
                                }
                            }
                            .mapStyle(.standard(elevation: .realistic))
                            .frame(height: 200)
                            .cornerRadius(VoyaraTheme.cornerRadius)
                        }
                        .padding(.horizontal, VoyaraTheme.spacing24)
                        
                        // Add to Trip Button
                        PrimaryButton("Add to Trip") {
                            showTripSelector = true
                        }
                        .padding(.horizontal, VoyaraTheme.spacing24)
                        
                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(VoyaraColors.primary)
                }
            }
            .sheet(isPresented: $showTripSelector) {
                NavigationStack {
                    List(tripViewModel.trips) { trip in
                        Button(action: {
                            if let firstDay = tripViewModel.itineraryDaysForTrip(trip).first {
                                let activity = ItineraryActivity(
                                    dayId: firstDay.id,
                                    title: "Visit \(destination.name)",
                                    startTime: Date(),
                                    endTime: Date().addingTimeInterval(7200),
                                    location: "\(destination.name), \(destination.country)",
                                    description: destination.description,
                                    category: .sightseeing,
                                    estimatedCost: 0,
                                    priority: .medium
                                )
                                tripViewModel.addActivityToDay(activity, dayId: firstDay.id, trip: trip)
                                showTripSelector = false
                                dismiss()
                            }
                        }) {
                            VStack(alignment: .leading) {
                                Text(trip.title).font(VoyaraTypography.headlineMedium).foregroundColor(VoyaraColors.text)
                                Text(trip.destination).font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
                            }
                        }
                    }
                    .navigationTitle("Select Trip")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showTripSelector = false }
                                .foregroundColor(VoyaraColors.primary)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: { showCreateNewTrip = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(VoyaraColors.primary)
                            }
                        }
                    }
                    .sheet(isPresented: $showCreateNewTrip) {
                        CreateTripView(initialDestination: "\(destination.name), \(destination.country)")
                    }
                }
            }
            .onAppear {
                loadActivities()
            }
        }
    }
    
    private func loadActivities() {
        guard let weather = weather else { return }
        Task {
            let activities = await VoyaraWeatherService.shared.generateActivities(for: weather)
            await MainActor.run {
                weatherActivities = activities
            }
        }
    }
}

// Make CategoryDestination Identifiable for sheet presentation
extension CategoryDestination: Equatable {
    static func == (lhs: CategoryDestination, rhs: CategoryDestination) -> Bool {
        lhs.id == rhs.id
    }
}
