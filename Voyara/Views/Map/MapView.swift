import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var mapViewModel: MapViewModel
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
                // Draw lines connecting the places
                if filteredPlaces.count > 1 {
                    MapPolyline(coordinates: filteredPlaces.map { $0.coordinate })
                        .stroke(VoyaraColors.primary, lineWidth: 3)
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
        }
        .sheet(item: $selectedPlace) { place in
            PlaceDetailView(place: place)
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Place Detail View
struct PlaceDetailView: View {
    let place: PlaceAnnotation
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripViewModel: TripViewModel
    @State private var isSaved = false
    @State private var showTripSelector = false
    
    // Sample images based on type
    private var headerImageName: String {
        switch place.type {
        case .landmark, .attraction: return "photo.artframe"
        case .restaurant: return "fork.knife"
        case .hotel: return "building.fill"
        default: return "photo"
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
                    .background(Color.white)
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
                }
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
