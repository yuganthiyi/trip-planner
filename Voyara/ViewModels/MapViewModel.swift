import Combine
import SwiftUI
import MapKit

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var places: [PlaceAnnotation] = []
    @Published var selectedPlace: PlaceAnnotation? = nil
    @Published var userLocation: CLLocationCoordinate2D? = nil
    @Published var region = MapRegion(
        latitude: 48.8566,
        longitude: 2.3522,
        latitudeDelta: 0.05,
        longitudeDelta: 0.05
    )
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    @Published var selectedCategory: PlaceType? = nil
    @Published var searchedAreaWeather: WeatherInfo? = nil
    @Published var searchedAreaActivities: [WeatherActivity] = []
    @Published var isLoadingWeather: Bool = false
    @Published var routes: [MKRoute] = []
    
    private let locationManager = CLLocationManager()
    
    var filteredPlaces: [PlaceAnnotation] {
        var result = places
        if let category = selectedCategory {
            result = result.filter { $0.type == category }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            DispatchQueue.main.async {
                self.userLocation = location.coordinate
                
                // If this is the first location update, center the map
                if self.userLocation != nil && !self.hasCenteredOnUser {
                    self.region = MapRegion(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        latitudeDelta: 0.05,
                        longitudeDelta: 0.05
                    )
                    self.hasCenteredOnUser = true
                }
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    @Published private var hasCenteredOnUser = false
    
    func fetchPlacesForTrip(_ trip: Trip) {
        isLoading = true
        
        Task {
            var annotations: [PlaceAnnotation] = []
            
            // 1. Add annotations from activities
            let allActivities = trip.itineraries.flatMap { $0.activities }
            let activityAnnotations = allActivities.compactMap { activity -> PlaceAnnotation? in
                guard let coord = activity.coordinate else { return nil }
                return PlaceAnnotation(
                    id: activity.id,
                    name: activity.title,
                    description: activity.description ?? activity.location ?? "",
                    latitude: coord.latitude,
                    longitude: coord.longitude,
                    type: .landmark,
                    rating: 0,
                    distance: 0,
                    reviews: [],
                    images: [],
                    hours: "Hours not specified",
                    address: activity.location ?? "",
                    website: nil
                )
            }
            annotations.append(contentsOf: activityAnnotations)
            
            // 2. Add annotations from trip destinations (if not already represented by activities)
            let destinations = trip.destinations ?? [trip.destination]
            for dest in destinations {
                // Skip if we already have an activity with this location name (simple heuristic)
                if activityAnnotations.contains(where: { $0.address.localizedCaseInsensitiveContains(dest) || $0.name.localizedCaseInsensitiveContains(dest) }) {
                    continue
                }
                
                // Geocode the destination string
                if let placemarks = try? await CLGeocoder().geocodeAddressString(dest),
                   let location = placemarks.first?.location {
                    let coord = location.coordinate
                    let destAnnotation = PlaceAnnotation(
                        id: UUID().uuidString,
                        name: dest,
                        description: "Trip Destination",
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        type: .landmark,
                        rating: 0,
                        distance: 0,
                        reviews: [],
                        images: [],
                        hours: "Trip level destination",
                        address: dest,
                        website: nil
                    )
                    annotations.append(destAnnotation)
                }
            }
            
            await MainActor.run {
                self.places = annotations
                self.isLoading = false
                
                // Adjust camera to fit annotations
                if let first = annotations.first {
                    self.region = MapRegion(
                        latitude: first.latitude,
                        longitude: first.longitude,
                        latitudeDelta: 0.2,
                        longitudeDelta: 0.2
                    )
                    
                    // Fetch weather for the first location
                    self.fetchWeatherForArea(latitude: first.latitude, longitude: first.longitude, name: first.name)
                }
                
                // Fetch routes between points
                self.fetchRoutes()
            }
        }
    }
    
    func fetchRoutes() {
        guard places.count > 1 else {
            self.routes = []
            return
        }
        
        let coordinates = places.map { $0.coordinate }
        var fetchedRoutes: [MKRoute] = []
        let group = DispatchGroup()
        
        for i in 0..<(coordinates.count - 1) {
            group.enter()
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinates[i]))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinates[i+1]))
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let route = response?.routes.first {
                    fetchedRoutes.append(route)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.routes = fetchedRoutes
        }
    }
    func selectPlace(_ place: PlaceAnnotation) {
        selectedPlace = place
    }
    
    func updateRegion(latitude: Double, longitude: Double) {
        region = MapRegion(
            latitude: latitude,
            longitude: longitude,
            latitudeDelta: 0.05,
            longitudeDelta: 0.05
        )
    }
    // MARK: - Real Search
    func searchRealPlaces(query: String) {
        guard !query.isEmpty else {
            self.places = []
            return
        }
        
        isLoading = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: region.latitude, longitude: region.longitude),
            span: MKCoordinateSpan(latitudeDelta: region.latitudeDelta, longitudeDelta: region.longitudeDelta)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let response = response, error == nil else { return }
                
                self?.places = response.mapItems.compactMap { item in
                    let coord = item.placemark.coordinate
                    return PlaceAnnotation(
                        id: UUID().uuidString,
                        name: item.name ?? "Unknown Place",
                        description: item.placemark.title ?? "No description available",
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        type: .landmark, // Defaulting for search results
                        rating: 4.5,
                        distance: 0,
                        reviews: [],
                        hours: "Hours not specified",
                        address: item.placemark.title ?? "Address not available"
                    )
                }
                
                // Recenter map on first result
                if let first = self?.places.first {
                    self?.region = MapRegion(latitude: first.latitude, longitude: first.longitude, latitudeDelta: 0.05, longitudeDelta: 0.05)
                    
                    // Also fetch weather for the searched area
                    self?.fetchWeatherForArea(latitude: first.latitude, longitude: first.longitude, name: query)
                }
            }
        }
    }
    
    // MARK: - Weather for Searched Area
    func fetchWeatherForArea(latitude: Double, longitude: Double, name: String? = nil) {
        isLoadingWeather = true
        
        Task {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let result = await VoyaraWeatherService.shared.fetchWeather(for: location)
            
            let activities: [WeatherActivity]
            if let current = result?.current {
                activities = await VoyaraWeatherService.shared.generateActivities(for: current)
            } else {
                activities = []
            }
            
            await MainActor.run {
                if let result = result {
                    var weather = result.current
                    weather.locationName = name
                    self.searchedAreaWeather = weather
                    self.searchedAreaActivities = activities
                }
                self.isLoadingWeather = false
            }
        }
    }
    
    // MARK: - Weather for specific place
    func fetchWeatherForPlace(_ place: PlaceAnnotation) {
        fetchWeatherForArea(latitude: place.latitude, longitude: place.longitude, name: place.name)
    }
}

// MARK: - Models
struct MapRegion {
    var latitude: Double
    var longitude: Double
    var latitudeDelta: Double
    var longitudeDelta: Double
}

struct PlaceAnnotation: Identifiable, Equatable {
    let id: String
    var name: String
    var description: String
    var latitude: Double
    var longitude: Double
    var type: PlaceType
    var rating: Double
    var distance: Double
    var reviews: [PlaceReview] = []
    var images: [String] = []
    var hours: String = "9:00 AM - 6:00 PM"
    var address: String = "Address not specified"
    var website: String? = nil
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static func == (lhs: PlaceAnnotation, rhs: PlaceAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

enum PlaceType: String, CaseIterable {
    case attraction = "Attraction"
    case restaurant = "Restaurant"
    case hotel = "Hotel"
    case park = "Park"
    case beach = "Beach"
    case landmark = "Landmark"
    
    var icon: String {
        switch self {
        case .attraction: return "star.fill"
        case .restaurant: return "fork.knife"
        case .hotel: return "bed.double.fill"
        case .park: return "leaf.fill"
        case .beach: return "sun.max.fill"
        case .landmark: return "mappin.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .attraction: return VoyaraColors.warning
        case .restaurant: return VoyaraColors.secondary
        case .hotel: return VoyaraColors.categoryHotel
        case .park: return VoyaraColors.success
        case .beach: return VoyaraColors.primaryLight
        case .landmark: return VoyaraColors.primary
        }
    }
}

struct PlaceReview: Identifiable {
    let id: String = UUID().uuidString
    var author: String
    var rating: Double
    var text: String
    var date: Date
}
