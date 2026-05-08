import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
            span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        )
    )
    @State private var selectedPlace: PlaceAnnotation?
    @State private var showDetail = false
    @State private var searchText = ""
    @State private var selectedCategory: PlaceType?
    
    var filteredPlaces: [PlaceAnnotation] {
        var result = mapViewModel.places
        if let cat = selectedCategory { result = result.filter { $0.type == cat } }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position) {
                // Draw actual road routes connecting the places
                ForEach(mapViewModel.routes, id: \.self) { route in
                    MapPolyline(route)
                        .stroke(VoyaraColors.primary, lineWidth: 5)
                }
                
                ForEach(filteredPlaces) { place in
                    Annotation(place.name, coordinate: place.coordinate) {
                        Button(action: { selectedPlace = place }) {
                            VStack(spacing: 2) {
                                Image(systemName: place.type.icon)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(place.type.color)
                                    .cornerRadius(8)
                                    .shadow(radius: 3)
                                
                                Image(systemName: "triangle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(place.type.color)
                                    .rotationEffect(.degrees(180))
                                    .offset(y: -4)
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea(edges: .bottom)
            
            // Search + Filters overlay
            VStack(spacing: VoyaraTheme.spacing8) {
                HStack(spacing: VoyaraTheme.spacing12) {
                    Image(systemName: "magnifyingglass").foregroundColor(VoyaraColors.textSecondary)
                    TextField("Search places...", text: $searchText)
                        .font(VoyaraTypography.bodyMedium)
                        .onSubmit {
                            mapViewModel.searchRealPlaces(query: searchText)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            mapViewModel.searchRealPlaces(query: "")
                        }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(VoyaraColors.textSecondary)
                        }
                    }
                }
                .padding(VoyaraTheme.spacing12)
                .background(.ultraThinMaterial)
                .cornerRadius(VoyaraTheme.mediumRadius)
                .shadow(radius: 4)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: VoyaraTheme.spacing8) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(PlaceType.allCases, id: \.self) { type in
                            FilterChip(title: type.rawValue, isSelected: selectedCategory == type) {
                                selectedCategory = (selectedCategory == type) ? nil : type
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, VoyaraTheme.spacing24)
            .padding(.top, VoyaraTheme.spacing8)
            
            // Weather badge overlay (bottom-left)
            if let weather = mapViewModel.searchedAreaWeather {
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: weather.conditionIcon)
                                    .font(.system(size: 16))
                                    .foregroundColor(weather.conditionColor)
                                Text("\(Int(weather.temperature))°C")
                                    .font(VoyaraTypography.headlineSmall)
                                    .foregroundColor(VoyaraColors.text)
                            }
                            Text(weather.condition)
                                .font(VoyaraTypography.captionSmall)
                                .foregroundColor(VoyaraColors.textSecondary)
                            if let name = weather.locationName {
                                Text(name)
                                    .font(VoyaraTypography.captionSmall)
                                    .foregroundColor(VoyaraColors.primary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(VoyaraTheme.spacing12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(VoyaraTheme.mediumRadius)
                        .shadow(radius: 4)
                        
                        Spacer()
                    }
                    .padding(.horizontal, VoyaraTheme.spacing24)
                    .padding(.bottom, VoyaraTheme.spacing32)
                }
            }
            
            // Discovery Overlay
            if selectedPlace == nil && searchText.isEmpty {
                VStack {
                    Spacer()
                    DiscoveryOverlay(mapVM: mapViewModel, position: $position, searchText: $searchText)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: $selectedPlace) { place in
            PlaceDetailView(place: place)
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Discovery Overlay
struct DiscoveryOverlay: View {
    @ObservedObject var mapVM: MapViewModel
    @EnvironmentObject var categoryViewModel: CategoryViewModel
    @Binding var position: MapCameraPosition
    @Binding var searchText: String
    
    var body: some View {
        let vm = mapVM
        let suggestions = categoryViewModel.suggestedDestinationsWithColors
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
            HStack {
                Text("Suggested Destinations")
                    .font(VoyaraTypography.headlineSmall)
                    .foregroundColor(VoyaraColors.text)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundColor(VoyaraColors.primary)
            }
            .padding(.horizontal, VoyaraTheme.spacing24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: VoyaraTheme.spacing16) {
                    ForEach(suggestions, id: \.destination.id) { pair in
                        Button(action: {
                            withAnimation(.spring()) {
                                position = .region(MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: pair.destination.latitude, longitude: pair.destination.longitude),
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                ))
                            }
                            searchText = pair.destination.name
                            vm.searchRealPlaces(query: pair.destination.name)
                        }) {
                            DestinationSuggestionCard(destination: pair.destination, color: pair.color)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            fetchWeatherForDestination(pair.destination)
                        }
                    }
                }
                .padding(.horizontal, VoyaraTheme.spacing24)
            }
        }
        .padding(.vertical, VoyaraTheme.spacing20)
        .background(.ultraThinMaterial)
        .cornerRadius(32, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: -5)
    }
    
    private func fetchWeatherForDestination(_ destination: CategoryDestination) {
        if mapVM.searchedAreaWeather == nil {
            mapVM.fetchWeatherForArea(latitude: destination.latitude, longitude: destination.longitude, name: destination.name)
        }
    }
}

// MARK: - Place Detail View
struct PlaceDetailView: View {
    let place: PlaceAnnotation
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripViewModel: TripViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @State private var isSaved = false
    @State private var showTripSelector = false
    @State private var showCreateNewTrip = false
    @State private var placeWeather: WeatherInfo? = nil
    @State private var placeActivities: [WeatherActivity] = []
    @State private var isLoadingWeather = true
    
    // Sample images based on type
    private var headerImageName: String {
        switch place.type {
        case .landmark: return "mountain.2.fill"
        case .attraction: return "camera.shutter.button.fill"
        case .restaurant: return "fork.knife.circle.fill"
        case .hotel: return "bed.double.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header Image Area
                    ZStack(alignment: .topLeading) {
                        // Background Image
                        GeometryReader { geometry in
                            let offset = geometry.frame(in: .global).minY
                            let isScrolledDown = offset > 0
                            
                            // Mocking an image background
                            ZStack {
                                if place.type == .hotel {
                                    Color.blue.opacity(0.3) // Pool/hotel mockup
                                } else {
                                    Color.orange.opacity(0.5) // Pyramids/sunset mockup
                                }
                                
                                Image(systemName: headerImageName)
                                    .font(.system(size: 80))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(width: geometry.size.width, height: isScrolledDown ? 300 + offset : 300)
                            .offset(y: isScrolledDown ? -offset : 0)
                            .clipped()
                        }
                        .frame(height: 300)
                        
                        // Back Button overlay
                        Button(action: { dismiss() }) {
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, 50)
                        .padding(.leading, VoyaraTheme.spacing20)
                    }
                    
                    // Content Body
                    VStack(alignment: .leading, spacing: VoyaraTheme.spacing20) {
                        // Title & Save
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.name)
                                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                                    .foregroundColor(VoyaraColors.text)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 14))
                                    Text(place.address.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? place.address)
                                        .font(.system(size: 15))
                                }
                                .foregroundColor(VoyaraColors.textSecondary)
                            }
                            Spacer()
                            Button(action: { isSaved.toggle() }) {
                                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 22))
                                    .foregroundColor(VoyaraColors.primary)
                            }
                        }
                        
                        // Description
                        Text(place.description)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(VoyaraColors.textSecondary)
                            .lineSpacing(4)
                        
                        // Hours
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Opening Hours")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(VoyaraColors.text)
                            Text(place.hours)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(VoyaraColors.textSecondary)
                        }
                        
                        // Weather Section
                        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
                            Text("Weather at Location")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(VoyaraColors.text)
                            
                            if isLoadingWeather {
                                HStack(spacing: VoyaraTheme.spacing8) {
                                    ProgressView().scaleEffect(0.8)
                                    Text("Loading weather...")
                                        .font(VoyaraTypography.bodySmall)
                                        .foregroundColor(VoyaraColors.textSecondary)
                                }
                                .padding(VoyaraTheme.spacing12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(VoyaraColors.surfaceVariant)
                                .cornerRadius(VoyaraTheme.mediumRadius)
                            } else if let weather = placeWeather {
                                VStack(spacing: VoyaraTheme.spacing12) {
                                    // Current conditions
                                    HStack(spacing: VoyaraTheme.spacing12) {
                                        Image(systemName: weather.conditionIcon)
                                            .font(.system(size: 32))
                                            .foregroundColor(weather.conditionColor)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(Int(weather.temperature))°C")
                                                .font(VoyaraTypography.displayMedium)
                                                .foregroundColor(VoyaraColors.text)
                                            Text(weather.condition)
                                                .font(VoyaraTypography.bodySmall)
                                                .foregroundColor(VoyaraColors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Label("\(Int(weather.humidity))%", systemImage: "drop.fill")
                                            Label("\(Int(weather.windSpeed)) km/h", systemImage: "wind")
                                        }
                                        .font(VoyaraTypography.captionSmall)
                                        .foregroundColor(VoyaraColors.textSecondary)
                                    }
                                    .padding(VoyaraTheme.spacing12)
                                    .background(VoyaraColors.surfaceVariant)
                                    .cornerRadius(VoyaraTheme.mediumRadius)
                                    
                                    // Activity suggestions
                                    if !placeActivities.isEmpty {
                                        Text("Suggested Activities")
                                            .font(VoyaraTypography.labelMedium)
                                            .foregroundColor(VoyaraColors.text)
                                        
                                        ForEach(placeActivities.prefix(3)) { activity in
                                            HStack(spacing: VoyaraTheme.spacing8) {
                                                Image(systemName: activity.icon)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .frame(width: 28, height: 28)
                                                    .background(activity.suitabilityColor)
                                                    .cornerRadius(8)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(activity.title)
                                                        .font(VoyaraTypography.bodySmall)
                                                        .foregroundColor(VoyaraColors.text)
                                                    Text(activity.isOutdoor ? "Outdoor" : "Indoor")
                                                        .font(VoyaraTypography.captionSmall)
                                                        .foregroundColor(VoyaraColors.textSecondary)
                                                }
                                                Spacer()
                                            }
                                            .padding(VoyaraTheme.spacing8)
                                            .background(VoyaraColors.surfaceVariant)
                                            .cornerRadius(VoyaraTheme.smallRadius)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Reviews
                        VStack(alignment: .leading, spacing: VoyaraTheme.spacing16) {
                            Text("Reviews (\(Int.random(in: 100...800)))")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(VoyaraColors.text)
                            
                            ForEach(place.reviews) { review in
                                HStack(alignment: .top, spacing: VoyaraTheme.spacing12) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.black)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(review.author)
                                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                                .foregroundColor(VoyaraColors.text)
                                            Spacer()
                                            Text(review.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.system(size: 12))
                                                .foregroundColor(VoyaraColors.textSecondary)
                                        }
                                        Text(review.text)
                                            .font(.system(size: 14, design: .rounded))
                                            .foregroundColor(VoyaraColors.textSecondary)
                                            .lineSpacing(2)
                                    }
                                }
                            }
                            
                            Button(action: {}) {
                                Text("See More")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(VoyaraColors.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, VoyaraTheme.spacing8)
                            }
                        }
                        
                        Spacer(minLength: 100) // Space for bottom button
                    }
                    .padding(VoyaraTheme.spacing24)
                    .background(VoyaraColors.surface)
                    .cornerRadius(32, corners: [.topLeft, .topRight])
                    .offset(y: -30)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Floating Add to Trip Button
            VStack {
                Spacer()
                Button(action: { showTripSelector = true }) {
                    Text("Add to trip")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(VoyaraColors.primary)
                        .cornerRadius(VoyaraTheme.mediumRadius)
                        .shadow(color: VoyaraColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, VoyaraTheme.spacing24)
                .padding(.bottom, VoyaraTheme.spacing32)
                .background(
                    LinearGradient(
                        colors: [.white.opacity(0.0), .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .offset(y: 20)
                )
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showTripSelector) {
            NavigationStack {
                List(tripViewModel.trips) { trip in
                    Button(action: {
                        if let firstDay = tripViewModel.itineraryDaysForTrip(trip).first {
                            let activity = ItineraryActivity(
                                dayId: firstDay.id,
                                title: place.name,
                                startTime: Date(),
                                endTime: Date().addingTimeInterval(3600),
                                location: place.address,
                                description: place.description,
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
                        Button("Cancel") { showTripSelector = false }.foregroundColor(VoyaraColors.primary)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showCreateNewTrip = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(VoyaraColors.primary)
                        }
                    }
                }
                .sheet(isPresented: $showCreateNewTrip) {
                    CreateTripView(initialDestination: place.address)
                }
            }
        }
        .onAppear {
            fetchPlaceWeather()
        }
    }
    
    private func fetchPlaceWeather() {
        isLoadingWeather = true
        Task {
            let location = CLLocation(latitude: place.latitude, longitude: place.longitude)
            let result = await VoyaraWeatherService.shared.fetchWeather(for: location)
            
            let activities: [WeatherActivity]
            if let current = result?.current {
                activities = await VoyaraWeatherService.shared.generateActivities(for: current)
            } else {
                activities = []
            }
            
            await MainActor.run {
                if let result = result {
                    placeWeather = result.current
                    placeActivities = activities
                }
                isLoadingWeather = false
            }
        }
    }
}

// Helper to round specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
