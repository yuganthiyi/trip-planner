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
        generateSamplePlaces()
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.generateSamplePlaces()
            self.isLoading = false
        }
    }
    
    private func generateSamplePlaces() {
        let samplePlaces = [
            PlaceAnnotation(
                id: "1",
                name: "Eiffel Tower",
                description: "Iconic iron lattice tower on the Champ de Mars, named after engineer Gustave Eiffel. One of the most recognizable structures in the world.",
                latitude: 48.8584,
                longitude: 2.2945,
                type: .landmark,
                rating: 4.8,
                distance: 2.5,
                reviews: [
                    PlaceReview(author: "Emma W.", rating: 5.0, text: "Absolutely breathtaking, especially at night! Must visit.", date: Date().addingTimeInterval(-86400 * 5)),
                    PlaceReview(author: "James L.", rating: 4.5, text: "Amazing views but can be crowded. Book tickets in advance.", date: Date().addingTimeInterval(-86400 * 12)),
                ],
                hours: "9:30 AM - 11:45 PM",
                address: "Champ de Mars, 5 Av. Anatole France, 75007 Paris",
                website: "https://www.toureiffel.paris"
            ),
            PlaceAnnotation(
                id: "2",
                name: "Louvre Museum",
                description: "The world's largest art museum and a historic monument in Paris. Home to the Mona Lisa and thousands of works of art.",
                latitude: 48.8606,
                longitude: 2.3376,
                type: .attraction,
                rating: 4.7,
                distance: 0.8,
                reviews: [
                    PlaceReview(author: "Sophie M.", rating: 5.0, text: "Could spend days here. The art collection is unmatched.", date: Date().addingTimeInterval(-86400 * 3)),
                ],
                hours: "9:00 AM - 6:00 PM",
                address: "Rue de Rivoli, 75001 Paris",
                website: "https://www.louvre.fr"
            ),
            PlaceAnnotation(
                id: "3",
                name: "Le Comptoir du Panthéon",
                description: "Charming Parisian brasserie serving classic French cuisine with views of the Panthéon.",
                latitude: 48.8462,
                longitude: 2.3461,
                type: .restaurant,
                rating: 4.6,
                distance: 1.2,
                reviews: [
                    PlaceReview(author: "Marco P.", rating: 4.5, text: "Excellent French cuisine with great atmosphere.", date: Date().addingTimeInterval(-86400 * 7)),
                ],
                hours: "12:00 PM - 11:00 PM",
                address: "5 Rue Soufflot, 75005 Paris"
            ),
            PlaceAnnotation(
                id: "4",
                name: "Luxembourg Gardens",
                description: "Beautiful 17th-century gardens covering 23 hectares. Perfect for a relaxing afternoon stroll.",
                latitude: 48.8462,
                longitude: 2.3372,
                type: .park,
                rating: 4.8,
                distance: 1.5,
                hours: "7:30 AM - 9:30 PM",
                address: "Rue de Médicis, 75006 Paris"
            ),
            PlaceAnnotation(
                id: "5",
                name: "Hôtel Plaza Athénée",
                description: "Legendary 5-star luxury hotel on Avenue Montaigne, the heart of Parisian haute couture.",
                latitude: 48.8660,
                longitude: 2.3025,
                type: .hotel,
                rating: 4.9,
                distance: 3.0,
                hours: "24 Hours",
                address: "25 Av. Montaigne, 75008 Paris",
                website: "https://www.plaza-athenee-paris.com"
            ),
            PlaceAnnotation(
                id: "6",
                name: "Notre-Dame Cathedral",
                description: "Medieval Catholic cathedral and UNESCO World Heritage Site. A masterpiece of French Gothic architecture.",
                latitude: 48.8530,
                longitude: 2.3499,
                type: .landmark,
                rating: 4.7,
                distance: 0.5,
                hours: "Currently under restoration",
                address: "6 Parvis Notre-Dame, 75004 Paris"
            ),
            PlaceAnnotation(
                id: "7",
                name: "Sacré-Cœur Basilica",
                description: "Romano-Byzantine basilica at the summit of Montmartre, the highest point in Paris.",
                latitude: 48.8867,
                longitude: 2.3431,
                type: .landmark,
                rating: 4.7,
                distance: 4.2,
                hours: "6:00 AM - 10:30 PM",
                address: "35 Rue du Chevalier de la Barre, 75018 Paris"
            ),
        ]
        
        self.places = samplePlaces
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
            generateSamplePlaces()
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
                }
            }
        }
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
