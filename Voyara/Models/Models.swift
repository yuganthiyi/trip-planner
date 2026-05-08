import Foundation
import CoreLocation

// MARK: - Trip Model
struct Trip: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    var title: String
    var description: String?
    var destination: String
    var destinations: [String]? = []
    var startDate: Date
    var endDate: Date
    var budget: Decimal
    var currency: String
    var status: TripStatus
    var coverImageURL: String?
    var category: String?
    var itineraries: [ItineraryDay]
    var expenses: [Expense]
    var packingItems: [PackingItem]
    var createdAt: Date
    var updatedAt: Date
    
    var durationDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    static func == (lhs: Trip, rhs: Trip) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Trip Status
enum TripStatus: String, Codable {
    case planning = "Planning"
    case ongoing = "Ongoing"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var icon: String {
        switch self {
        case .planning: return "pencil.and.list.clipboard"
        case .ongoing: return "airplane"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Itinerary
struct ItineraryDay: Identifiable, Codable {
    let id: String
    let tripId: String
    let dayNumber: Int
    let date: Date
    var activities: [ItineraryActivity]
    
    init(id: String = UUID().uuidString, tripId: String, dayNumber: Int, date: Date, activities: [ItineraryActivity] = []) {
        self.id = id
        self.tripId = tripId
        self.dayNumber = dayNumber
        self.date = date
        self.activities = activities
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var totalCost: Decimal {
        activities.reduce(0) { $0 + $1.estimatedCost }
    }
    
    var completionPercentage: Double {
        guard !activities.isEmpty else { return 0 }
        let completed = activities.filter { $0.isCompleted }.count
        return Double(completed) / Double(activities.count) * 100
    }
}

// MARK: - Activity
struct ItineraryActivity: Identifiable, Codable, Equatable {
    let id: String
    let dayId: String
    var title: String
    var startTime: Date
    var endTime: Date
    var location: String?
    var latitude: Double?
    var longitude: Double?
    var description: String?
    var category: ActivityCategory
    var estimatedCost: Decimal
    var isCompleted: Bool
    var priority: Priority
    var notes: String?
    
    init(id: String = UUID().uuidString, dayId: String, title: String, startTime: Date, endTime: Date,
         location: String? = nil, latitude: Double? = nil, longitude: Double? = nil,
         description: String? = nil, category: ActivityCategory,
         estimatedCost: Decimal, isCompleted: Bool = false, priority: Priority = .medium, notes: String? = nil) {
        self.id = id
        self.dayId = dayId
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.description = description
        self.category = category
        self.estimatedCost = estimatedCost
        self.isCompleted = isCompleted
        self.priority = priority
        self.notes = notes
    }
    
    static func == (lhs: ItineraryActivity, rhs: ItineraryActivity) -> Bool {
        lhs.id == rhs.id
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

enum ActivityCategory: String, Codable, CaseIterable {
    case sightseeing = "Sightseeing"
    case dining = "Dining"
    case transport = "Transport"
    case accommodation = "Accommodation"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case outdoor = "Outdoor"
    case wellness = "Wellness"
    case culture = "Culture"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .sightseeing: return "binoculars.fill"
        case .dining: return "fork.knife"
        case .transport: return "car.fill"
        case .accommodation: return "bed.double.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "party.popper.fill"
        case .outdoor: return "mountain.2.fill"
        case .wellness: return "figure.mind.and.body"
        case .culture: return "building.columns.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: SwiftUI.Color {
        switch self {
        case .sightseeing: return VoyaraColors.primary
        case .dining: return VoyaraColors.secondary
        case .transport: return VoyaraColors.categoryTransport
        case .accommodation: return VoyaraColors.categoryHotel
        case .shopping: return VoyaraColors.categoryShopping
        case .entertainment: return VoyaraColors.warning
        case .outdoor: return VoyaraColors.success
        case .wellness: return VoyaraColors.accent
        case .culture: return VoyaraColors.primaryDark
        case .other: return VoyaraColors.categoryOther
        }
    }
}

enum Priority: String, Codable, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

// MARK: - Expense
struct Expense: Identifiable, Codable, Equatable {
    let id: String
    let tripId: String
    let activityId: String?
    var title: String
    var amount: Decimal
    var category: String
    var date: Date
    var paymentMethod: String = "Cash"
    var notes: String?
    
    static func == (lhs: Expense, rhs: Expense) -> Bool {
        lhs.id == rhs.id
    }
}

enum ExpenseCategory: String, CaseIterable, Codable {
    case food = "Food & Dining"
    case transportation = "Transportation"
    case accommodation = "Accommodation"
    case activities = "Activities"
    case shopping = "Shopping"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .accommodation: return "bed.double.fill"
        case .activities: return "ticket.fill"
        case .shopping: return "bag.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: SwiftUI.Color {
        switch self {
        case .food: return VoyaraColors.categoryFood
        case .transportation: return VoyaraColors.categoryTransport
        case .accommodation: return VoyaraColors.categoryHotel
        case .activities: return VoyaraColors.categoryActivity
        case .shopping: return VoyaraColors.categoryShopping
        case .other: return VoyaraColors.categoryOther
        }
    }
}

// MARK: - Packing Item
struct PackingItem: Identifiable, Codable, Equatable {
    let id: String
    let tripId: String
    var name: String
    var category: String
    var quantity: Int
    var isPacked: Bool = false
    
    static func == (lhs: PackingItem, rhs: PackingItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Weather Models
struct WeatherInfo: Identifiable {
    let id = UUID().uuidString
    var temperature: Double
    var feelsLike: Double
    var condition: String
    var humidity: Double
    var windSpeed: Double
    var uvIndex: Double
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    
    var conditionIcon: String {
        switch condition.lowercased() {
        case "sunny", "clear": return "sun.max.fill"
        case "cloudy", "overcast": return "cloud.fill"
        case "partly cloudy", "mainly clear": return "cloud.sun.fill"
        case "rainy", "rain", "light rain", "moderate rain", "heavy rain": return "cloud.rain.fill"
        case "drizzle", "light drizzle": return "cloud.drizzle.fill"
        case "thunderstorm": return "cloud.bolt.rain.fill"
        case "snowy", "snow", "light snow": return "cloud.snow.fill"
        case "fog", "foggy", "mist": return "cloud.fog.fill"
        default: return "sun.max.fill"
        }
    }
    
    var conditionColor: SwiftUI.Color {
        switch condition.lowercased() {
        case "sunny", "clear": return .yellow
        case "cloudy", "overcast": return .gray
        case "partly cloudy", "mainly clear": return Color(red: 0.6, green: 0.7, blue: 0.9)
        case "rainy", "rain", "light rain", "moderate rain", "heavy rain", "drizzle": return .blue
        case "thunderstorm": return .purple
        case "snowy", "snow", "light snow": return .cyan
        case "fog", "foggy", "mist": return .gray
        default: return .yellow
        }
    }
}

struct DailyForecast: Identifiable {
    let id = UUID().uuidString
    var day: Date
    var high: Double
    var low: Double
    var condition: String
    
    var conditionIcon: String {
        switch condition.lowercased() {
        case "sunny", "clear": return "sun.max.fill"
        case "cloudy", "overcast": return "cloud.fill"
        case "partly cloudy", "mainly clear": return "cloud.sun.fill"
        case "rainy", "rain", "light rain", "moderate rain", "heavy rain": return "cloud.rain.fill"
        case "drizzle", "light drizzle", "freezing drizzle": return "cloud.drizzle.fill"
        case "thunderstorm": return "cloud.bolt.rain.fill"
        case "snowy", "snow", "light snow", "heavy snow": return "cloud.snow.fill"
        case "fog": return "cloud.fog.fill"
        case "freezing rain": return "cloud.sleet.fill"
        default: return "sun.max.fill"
        }
    }
    
    var conditionColor: Color {
        switch condition.lowercased() {
        case "sunny", "clear": return .yellow
        case "cloudy", "overcast": return .gray
        case "partly cloudy", "mainly clear": return Color(red: 0.6, green: 0.7, blue: 0.9)
        case "rainy", "rain", "light rain", "moderate rain", "heavy rain", "drizzle": return .blue
        case "thunderstorm": return .purple
        case "snowy", "snow", "light snow", "heavy snow": return .cyan
        case "fog": return .gray
        default: return .yellow
        }
    }
}

// MARK: - Weather Suggestion
struct WeatherSuggestion: Identifiable {
    let id = UUID().uuidString
    var title: String
    var description: String
    var icon: String
    var priority: Priority
    var type: SuggestionType
    
    enum SuggestionType: String {
        case clothing = "Clothing"
        case activity = "Activity"
        case packing = "Packing"
    }
}

// MARK: - Explore Category
struct ExploreCategory: Identifiable, Codable {
    let id: String
    var title: String
    var icon: String
    var colorHex: String
    var destinationCount: Int
    var destinations: [CategoryDestination]
    
    init(id: String = UUID().uuidString, title: String, icon: String, colorHex: String, destinationCount: Int = 0, destinations: [CategoryDestination] = []) {
        self.id = id
        self.title = title
        self.icon = icon
        self.colorHex = colorHex
        self.destinationCount = destinationCount
        self.destinations = destinations
    }
    
    var color: SwiftUI.Color {
        Color(hex: colorHex) ?? VoyaraColors.primary
    }
}

struct CategoryDestination: Identifiable, Codable {
    let id: String
    var name: String
    var country: String
    var latitude: Double
    var longitude: Double
    var description: String
    var rating: Double
    var imageURL: String?
    var weatherSuitability: String?
    
    init(id: String = UUID().uuidString, name: String, country: String, latitude: Double, longitude: Double, description: String, rating: Double, imageURL: String? = nil, weatherSuitability: String? = nil) {
        self.id = id
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.description = description
        self.rating = rating
        self.imageURL = imageURL
        self.weatherSuitability = weatherSuitability
    }
}

// MARK: - Weather Activity
struct WeatherActivity: Identifiable {
    let id = UUID().uuidString
    var title: String
    var description: String
    var icon: String
    var category: ActivityCategory
    var suitableConditions: [String]
    var temperatureRange: ClosedRange<Double>
    var isOutdoor: Bool
    
    var suitabilityColor: SwiftUI.Color {
        isOutdoor ? VoyaraColors.success : VoyaraColors.primary
    }
}

// MARK: - Color Hex Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - App Notification
struct AppNotification: Identifiable, Equatable, Codable {
    let id: String
    var title: String
    var message: String
    var type: NotificationType
    var isRead: Bool
    var timestamp: Date
    var tripId: String?
    
    static func == (lhs: AppNotification, rhs: AppNotification) -> Bool {
        lhs.id == rhs.id
    }
}

enum NotificationType: String, Codable {
    case tripReminder = "Trip Reminder"
    case budgetAlert = "Budget Alert"
    case weatherUpdate = "Weather Update"
    case packingReminder = "Packing Reminder"
    case tripSharing = "Trip Sharing"
    case general = "General"
    
    var icon: String {
        switch self {
        case .tripReminder: return "calendar.badge.clock"
        case .budgetAlert: return "dollarsign.circle.fill"
        case .weatherUpdate: return "cloud.sun.fill"
        case .packingReminder: return "bag.fill"
        case .tripSharing: return "person.2.fill"
        case .general: return "bell.fill"
        }
    }
}

// MARK: - Optimized Itinerary
struct OptimizedItinerary {
    var originalActivities: [ItineraryActivity]
    var optimizedActivities: [ItineraryActivity]
    var optimizationType: OptimizationType
    var estimatedTimeSaved: Int
    var estimatedCostSaved: Decimal
    var efficiency: Double
}

enum OptimizationType: String {
    case time = "Time Optimized"
    case cost = "Cost Optimized"
    case combined = "Smart Optimized"
}

// MARK: - Import SwiftUI for Color references
import SwiftUI
