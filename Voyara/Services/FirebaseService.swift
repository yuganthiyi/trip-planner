import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Firebase Service
actor FirebaseService {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Current User
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Categories
    func fetchCategories() async throws -> [ExploreCategory] {
        guard let uid = userId else { return [] }
        
        let snapshot = try await db.collection("users").document(uid).collection("categories").getDocuments()
        
        let categories = snapshot.documents.compactMap { doc -> ExploreCategory? in
            guard let data = try? JSONSerialization.data(withJSONObject: doc.data()) else { return nil }
            let decoder = JSONDecoder()
            return try? decoder.decode(ExploreCategory.self, from: data)
        }
        
        return categories.sorted { $0.title < $1.title }
    }
    
    func saveCategory(_ category: ExploreCategory) async throws {
        guard let uid = userId else { return }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(category)
        if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            try await db.collection("users").document(uid).collection("categories").document(category.id).setData(dict)
        }
    }
    
    func saveCategories(_ categories: [ExploreCategory]) async throws {
        guard let uid = userId else { return }
        
        let batch = db.batch()
        let encoder = JSONEncoder()
        
        for category in categories {
            if let data = try? encoder.encode(category),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let docRef = db.collection("users").document(uid).collection("categories").document(category.id)
                batch.setData(dict, forDocument: docRef)
            }
        }
        
        try await batch.commit()
    }
    
    // MARK: - Seed Initial Categories (first launch)
    func seedCategoriesIfNeeded() async {
        guard let uid = userId else { return }
        
        do {
            let snapshot = try await db.collection("users").document(uid).collection("categories").getDocuments()
            
            if snapshot.documents.isEmpty {
                let defaultCategories = Self.defaultCategories()
                try await saveCategories(defaultCategories)
            }
        } catch {
            print("Error seeding categories: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Default Categories with Real Destinations
    static func defaultCategories() -> [ExploreCategory] {
        return [
            ExploreCategory(
                title: "Adventure",
                icon: "mountain.2.fill",
                colorHex: "33CC66",
                destinationCount: 6,
                destinations: [
                    CategoryDestination(name: "Queenstown", country: "New Zealand", latitude: -45.0312, longitude: 168.6626, description: "Bungee jumping, skydiving, and jet boating capital of the world.", rating: 4.9, imageURL: "https://images.unsplash.com/photo-1589802829985-817e51181b92?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Interlaken", country: "Switzerland", latitude: 46.6863, longitude: 7.8632, description: "Paragliding over the Swiss Alps with stunning lake views.", rating: 4.8, imageURL: "https://images.unsplash.com/photo-1527668752968-14dc70a27c95?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Moab", country: "USA", latitude: 38.5733, longitude: -109.5498, description: "Red rock canyons, mountain biking, and Arches National Park.", rating: 4.7, imageURL: "https://images.unsplash.com/photo-1505933349320-a3990f52229a?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Chamonix", country: "France", latitude: 45.9237, longitude: 6.8694, description: "World-class skiing and mountaineering at Mont Blanc.", rating: 4.8, imageURL: "https://images.unsplash.com/photo-1549400853-291f37ed9875?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Cusco", country: "Peru", latitude: -13.5320, longitude: -71.9675, description: "Gateway to Machu Picchu and the Inca Trail.", rating: 4.7, imageURL: "https://images.unsplash.com/photo-1526392060635-9d6019884377?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Cape Town", country: "South Africa", latitude: -33.9249, longitude: 18.4241, description: "Table Mountain, shark cage diving, and coastline adventures.", rating: 4.8, imageURL: "https://images.unsplash.com/photo-1580619305218-8423a7ef79b4?auto=format&fit=crop&w=400&h=300"),
                ]
            ),
            ExploreCategory(
                title: "City Break",
                icon: "building.2.fill",
                colorHex: "3399FF",
                destinationCount: 6,
                destinations: [
                    CategoryDestination(name: "Paris", country: "France", latitude: 48.8566, longitude: 2.3522, description: "The City of Light — Eiffel Tower, Louvre, and world-class dining.", rating: 4.8, imageURL: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Tokyo", country: "Japan", latitude: 35.6762, longitude: 139.6503, description: "Ancient temples, neon-lit streets, and incredible cuisine.", rating: 4.9, imageURL: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "New York", country: "USA", latitude: 40.7128, longitude: -74.0060, description: "The Big Apple — Broadway, Central Park, and iconic skyline.", rating: 4.7, imageURL: "https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Barcelona", country: "Spain", latitude: 41.3874, longitude: 2.1686, description: "Gaudí architecture, tapas, and Mediterranean beaches.", rating: 4.8, imageURL: "https://images.unsplash.com/photo-1583422409516-2895a77efded?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Istanbul", country: "Turkey", latitude: 41.0082, longitude: 28.9784, description: "Where East meets West — bazaars, mosques, and Bosphorus views.", rating: 4.7, imageURL: "https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "London", country: "UK", latitude: 51.5074, longitude: -0.1278, description: "Royal palaces, West End shows, and historic landmarks.", rating: 4.7, imageURL: "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&w=400&h=300"),
                ]
            ),
            ExploreCategory(
                title: "Beach",
                icon: "sun.max.fill",
                colorHex: "FFAA00",
                destinationCount: 6,
                destinations: [
                    CategoryDestination(name: "Maldives", country: "Maldives", latitude: 3.2028, longitude: 73.2207, description: "Crystal-clear waters, overwater villas, and pristine coral reefs.", rating: 4.9, imageURL: "https://images.unsplash.com/photo-1514282401047-d79a71a590e8?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Bali", country: "Indonesia", latitude: -8.3405, longitude: 115.0920, description: "Tropical paradise with terraced rice paddies and surf beaches.", rating: 4.8, imageURL: "https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Santorini", country: "Greece", latitude: 36.3932, longitude: 25.4615, description: "Iconic white-washed buildings, volcanic beaches, and sunsets.", rating: 4.8, imageURL: "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Cancún", country: "Mexico", latitude: 21.1619, longitude: -86.8515, description: "Caribbean turquoise waters, Mayan ruins, and nightlife.", rating: 4.6, imageURL: "https://images.unsplash.com/photo-1552074284-5e88ef1aef18?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Phuket", country: "Thailand", latitude: 7.8804, longitude: 98.3923, description: "Stunning beaches, vibrant nightlife, and Thai cuisine.", rating: 4.7, imageURL: "https://images.unsplash.com/photo-1589394815804-964ed9be2eb3?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Zanzibar", country: "Tanzania", latitude: -6.1659, longitude: 39.2026, description: "Spice island with white sand beaches and rich culture.", rating: 4.7, imageURL: "https://images.unsplash.com/photo-1586861635167-e5223aadc9fe?auto=format&fit=crop&w=400&h=300"),
                ]
            ),
            ExploreCategory(
                title: "Food Tour",
                icon: "fork.knife",
                colorHex: "F2994A",
                destinationCount: 6,
                destinations: [
                    CategoryDestination(name: "Bologna", country: "Italy", latitude: 44.4949, longitude: 11.3426, description: "The food capital of Italy — fresh pasta, ragù, and gelato.", rating: 4.9, imageURL: "https://images.unsplash.com/photo-1595196112051-bc438e3e970a?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Bangkok", country: "Thailand", latitude: 13.7563, longitude: 100.5018, description: "Street food paradise — pad thai, green curry, and mango sticky rice.", rating: 4.8, imageURL: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "San Sebastián", country: "Spain", latitude: 43.3183, longitude: -1.9812, description: "Pintxos bars and Michelin-starred restaurants by the sea.", rating: 4.9, imageURL: "https://images.unsplash.com/photo-1515443961218-1523678885b8?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Osaka", country: "Japan", latitude: 34.6937, longitude: 135.5023, description: "Japan's kitchen — takoyaki, okonomiyaki, and ramen.", rating: 4.8, imageURL: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Marrakech", country: "Morocco", latitude: 31.6295, longitude: -7.9811, description: "Spice markets, tagines, and traditional Moroccan cuisine.", rating: 4.7, imageURL: "https://images.unsplash.com/photo-1539020140153-e479b7c2b3df?auto=format&fit=crop&w=400&h=300"),
                    CategoryDestination(name: "Lima", country: "Peru", latitude: -12.0464, longitude: -77.0428, description: "World-class ceviche and South America's culinary capital.", rating: 4.8, imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=400&h=300"),
                ]
            ),
        ]
    }
}
