import Combine
import SwiftUI
import CoreLocation
import WeatherKit

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.first {
            location = loc
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// MARK: - Weather View Model
class WeatherViewModel: ObservableObject {
    @Published var currentWeather: WeatherInfo?
    @Published var forecast: [DailyForecast] = []
    @Published var suggestions: [WeatherSuggestion] = []
    @Published var isLoading: Bool = false
    
    let locationManager = LocationManager()
    private let weatherService = WeatherService.shared
    
    init() {
        loadSampleData()
    }
    
    // Attempt to fetch real weather data via WeatherKit
    func fetchWeather(for destination: String? = nil) {
        isLoading = true
        
        Task {
            // Try to use current location if destination is not provided
            var targetLocation: CLLocation? = locationManager.location
            
            // Wait for location if not available
            if targetLocation == nil && locationManager.authorizationStatus == .authorizedWhenInUse {
                locationManager.requestLocation()
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait up to 2 seconds for location
                targetLocation = locationManager.location
            }
            
            // If we have a location, try WeatherKit
            if let location = targetLocation {
                do {
                    let weather = try await weatherService.weather(for: location)
                    
                    DispatchQueue.main.async {
                        self.currentWeather = WeatherInfo(
                            temperature: weather.currentWeather.temperature.value,
                            feelsLike: weather.currentWeather.apparentTemperature.value,
                            condition: weather.currentWeather.condition.description,
                            humidity: weather.currentWeather.humidity * 100,
                            windSpeed: weather.currentWeather.wind.speed.value,
                            uvIndex: Double(weather.currentWeather.uvIndex.value)
                        )
                        
                        self.forecast = weather.dailyForecast.map { day in
                            DailyForecast(
                                day: day.date,
                                high: day.highTemperature.value,
                                low: day.lowTemperature.value,
                                condition: day.condition.description
                            )
                        }
                        self.generateDynamicSuggestions(from: weather.currentWeather)
                        self.isLoading = false
                    }
                    return
                } catch {
                    print("WeatherKit failed: \(error.localizedDescription). Falling back to sample data.")
                }
            }
            
            // Fallback to sample data if WeatherKit fails (e.g. no developer capability) or no location
            DispatchQueue.main.async {
                self.loadSampleData()
                self.isLoading = false
            }
        }
    }
    
    // Generate suggestions based on real WeatherKit data
    private func generateDynamicSuggestions(from current: CurrentWeather) {
        var newSuggestions: [WeatherSuggestion] = []
        
        // Temperature suggestions
        let temp = current.temperature.value
        if temp < 10 {
            newSuggestions.append(WeatherSuggestion(title: "Pack Heavy Coat", description: "Temperatures are below 10°C. Bring a warm jacket.", icon: "snowflake", priority: .high, type: .clothing))
        } else if temp > 28 {
            newSuggestions.append(WeatherSuggestion(title: "Stay Hydrated", description: "It's quite hot today (\(Int(temp))°C). Drink plenty of water.", icon: "drop.fill", priority: .high, type: .activity))
            newSuggestions.append(WeatherSuggestion(title: "Light Clothing", description: "Wear breathable fabrics for the heat.", icon: "tshirt.fill", priority: .medium, type: .clothing))
        } else {
            newSuggestions.append(WeatherSuggestion(title: "Perfect Weather", description: "Great temperature for outdoor activities.", icon: "figure.walk", priority: .low, type: .activity))
        }
        
        // UV suggestions
        if current.uvIndex.value >= 6 {
            newSuggestions.append(WeatherSuggestion(title: "Sunscreen Essential", description: "High UV Index (\(current.uvIndex.value)). Apply sunscreen regularly.", icon: "sun.max.fill", priority: .high, type: .packing))
        }
        
        // Condition suggestions
        let condition = current.condition.description.lowercased()
        if condition.contains("rain") || condition.contains("drizzle") {
            newSuggestions.append(WeatherSuggestion(title: "Bring an Umbrella", description: "Rain is expected. Keep an umbrella handy.", icon: "umbrella.fill", priority: .high, type: .packing))
            newSuggestions.append(WeatherSuggestion(title: "Indoor Activities", description: "Consider visiting museums or indoor attractions.", icon: "building.columns.fill", priority: .medium, type: .activity))
        } else if condition.contains("snow") {
            newSuggestions.append(WeatherSuggestion(title: "Winter Gear", description: "Snow is expected. Bring waterproof boots and gloves.", icon: "mitten.fill", priority: .high, type: .clothing))
        }
        
        if newSuggestions.isEmpty {
            newSuggestions.append(WeatherSuggestion(title: "Enjoy Your Trip", description: "Weather looks stable. Enjoy your activities!", icon: "star.fill", priority: .low, type: .activity))
        }
        
        suggestions = newSuggestions
    }
    
    private func loadSampleData() {
        currentWeather = WeatherInfo(
            temperature: 24,
            feelsLike: 26,
            condition: "Partly Cloudy",
            humidity: 55,
            windSpeed: 12,
            uvIndex: 6
        )
        
        forecast = (0..<7).map { i in
            DailyForecast(
                day: Calendar.current.date(byAdding: .day, value: i, to: Date()) ?? Date(),
                high: Double.random(in: 22...30),
                low: Double.random(in: 14...20),
                condition: ["Sunny", "Partly Cloudy", "Cloudy", "Sunny", "Rainy", "Sunny", "Partly Cloudy"][i]
            )
        }
        
        suggestions = [
            WeatherSuggestion(title: "Pack Light Layers", description: "Temperatures range from 14°C to 28°C. Bring layers you can add or remove easily.", icon: "tshirt.fill", priority: .high, type: .clothing),
            WeatherSuggestion(title: "Bring an Umbrella", description: "Rain expected on Day 5. Keep a compact umbrella in your day bag.", icon: "umbrella.fill", priority: .medium, type: .packing),
            WeatherSuggestion(title: "Sunscreen Essential", description: "UV Index reaching 6+. Apply SPF 50 sunscreen regularly.", icon: "sun.max.fill", priority: .high, type: .packing),
            WeatherSuggestion(title: "Best for Sightseeing", description: "Days 1, 4, and 6 have the best weather for outdoor activities.", icon: "figure.walk", priority: .medium, type: .activity),
            WeatherSuggestion(title: "Museum Day", description: "Day 5 is rainy - perfect for visiting indoor attractions like the Louvre.", icon: "building.columns.fill", priority: .low, type: .activity),
            WeatherSuggestion(title: "Comfortable Shoes", description: "Plan for 10,000+ steps per day. Pack your most comfortable walking shoes.", icon: "shoe.fill", priority: .medium, type: .clothing),
        ]
    }
}
