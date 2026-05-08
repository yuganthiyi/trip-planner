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
            // Keep tracking live location but don't stop manager
            // User requested live tracking
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
    @Published var weatherActivities: [WeatherActivity] = []
    @Published var isLoading: Bool = false
    @Published var locationName: String = "Detecting location..."
    @Published var errorMessage: String?
    
    let locationManager = LocationManager()
    private let weatherService = VoyaraWeatherService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe location changes and auto-fetch weather
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.fetchWeatherForLocation(location)
            }
            .store(in: &cancellables)
        
        locationManager.requestLocation()
    }
    
    // MARK: - Fetch weather for current device location
    private func fetchWeatherForLocation(_ location: CLLocation) {
        isLoading = true
        errorMessage = nil
        
        Task {
            // Get location name
            let name = await weatherService.reverseGeocode(location)
            
            // Fetch weather
            let result = await weatherService.fetchWeather(for: location)
            
            // Generate activities
            let activities: [WeatherActivity]
            if let currentInfo = result?.current {
                activities = await weatherService.generateActivities(for: currentInfo)
            } else {
                activities = []
            }
            
            await MainActor.run {
                self.locationName = name
                
                if let result = result {
                    var weatherInfo = result.current
                    weatherInfo.locationName = name
                    self.currentWeather = weatherInfo
                    self.forecast = result.forecast
                    self.weatherActivities = activities
                    self.generateSuggestions(from: weatherInfo)
                } else {
                    self.errorMessage = "Unable to fetch weather data."
                }
                self.isLoading = false
            }
        }
    }
    
    func refreshWeather() {
        if let loc = locationManager.location {
            fetchWeatherForLocation(loc)
        } else {
            locationManager.requestLocation()
        }
    }
    
    // MARK: - Fetch weather for a destination string (geocodes it first)
    func fetchWeather(for destination: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        Task {
            var targetLocation: CLLocation?
            
            // If destination provided, geocode it
            if let destination = destination, !destination.isEmpty {
                do {
                    targetLocation = try await weatherService.geocodeDestination(destination)
                } catch {
                    print("Geocoding failed for '\(destination)': \(error.localizedDescription)")
                }
            }
            
            // Fall back to current location
            if targetLocation == nil {
                targetLocation = locationManager.location
            }
            
            // Wait for location if still nil
            if targetLocation == nil && (locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways) {
                locationManager.requestLocation()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                targetLocation = locationManager.location
            }
            
            guard let location = targetLocation else {
                await MainActor.run {
                    self.errorMessage = "Location unavailable. Enable location services."
                    self.isLoading = false
                }
                return
            }
            
            // Get location name
            let name: String
            if let destination = destination, !destination.isEmpty {
                name = destination
            } else {
                name = await weatherService.reverseGeocode(location)
            }
            
            // Fetch weather
            let result = await weatherService.fetchWeather(for: location)
            
            // Generate activities
            let activities: [WeatherActivity]
            if let currentInfo = result?.current {
                activities = await weatherService.generateActivities(for: currentInfo)
            } else {
                activities = []
            }
            
            await MainActor.run {
                self.locationName = name
                
                if let result = result {
                    var weatherInfo = result.current
                    weatherInfo.locationName = name
                    self.currentWeather = weatherInfo
                    self.forecast = result.forecast
                    self.weatherActivities = activities
                    self.generateSuggestions(from: weatherInfo)
                } else {
                    self.errorMessage = "Unable to fetch weather data."
                }
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Fetch weather for specific coordinates (used by Map)
    func fetchWeatherForCoordinate(latitude: Double, longitude: Double, name: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        Task {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            
            let locationName: String
            if let name = name, !name.isEmpty {
                locationName = name
            } else {
                locationName = await weatherService.reverseGeocode(location)
            }
            
            let result = await weatherService.fetchWeather(for: location)
            
            let activities: [WeatherActivity]
            if let currentInfo = result?.current {
                activities = await weatherService.generateActivities(for: currentInfo)
            } else {
                activities = []
            }
            
            await MainActor.run {
                self.locationName = locationName
                
                if let result = result {
                    var weatherInfo = result.current
                    weatherInfo.locationName = locationName
                    self.currentWeather = weatherInfo
                    self.forecast = result.forecast
                    self.weatherActivities = activities
                    self.generateSuggestions(from: weatherInfo)
                } else {
                    self.errorMessage = "Unable to fetch weather for this location."
                }
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Generate packing/travel suggestions based on weather
    private func generateSuggestions(from weather: WeatherInfo) {
        var newSuggestions: [WeatherSuggestion] = []
        let temp = weather.temperature
        let condition = weather.condition.lowercased()
        
        // Temperature suggestions
        if temp < 10 {
            newSuggestions.append(WeatherSuggestion(title: "Pack Heavy Coat", description: "Temperatures are below 10°C. Bring a warm jacket and layers.", icon: "snowflake", priority: .high, type: .clothing))
        } else if temp > 28 {
            newSuggestions.append(WeatherSuggestion(title: "Stay Hydrated", description: "It's quite hot today (\(Int(temp))°C). Drink plenty of water.", icon: "drop.fill", priority: .high, type: .activity))
            newSuggestions.append(WeatherSuggestion(title: "Light Clothing", description: "Wear breathable fabrics for the heat.", icon: "tshirt.fill", priority: .medium, type: .clothing))
        } else {
            newSuggestions.append(WeatherSuggestion(title: "Perfect Weather", description: "Great temperature (\(Int(temp))°C) for outdoor activities.", icon: "figure.walk", priority: .low, type: .activity))
        }
        
        // UV suggestions
        if weather.uvIndex >= 6 {
            newSuggestions.append(WeatherSuggestion(title: "Sunscreen Essential", description: "High UV Index (\(Int(weather.uvIndex))). Apply SPF 50 sunscreen regularly.", icon: "sun.max.fill", priority: .high, type: .packing))
        }
        
        // Wind suggestions
        if weather.windSpeed > 40 {
            newSuggestions.append(WeatherSuggestion(title: "Strong Winds", description: "Wind speeds of \(Int(weather.windSpeed)) km/h. Secure loose items.", icon: "wind", priority: .high, type: .packing))
        }
        
        // Condition suggestions
        if condition.contains("rain") || condition.contains("drizzle") {
            newSuggestions.append(WeatherSuggestion(title: "Bring an Umbrella", description: "Rain is expected. Keep a compact umbrella in your day bag.", icon: "umbrella.fill", priority: .high, type: .packing))
            newSuggestions.append(WeatherSuggestion(title: "Indoor Activities", description: "Consider visiting museums or indoor attractions today.", icon: "building.columns.fill", priority: .medium, type: .activity))
        } else if condition.contains("snow") {
            newSuggestions.append(WeatherSuggestion(title: "Winter Gear", description: "Snow is expected. Bring waterproof boots and gloves.", icon: "snowflake", priority: .high, type: .clothing))
        } else if condition.contains("fog") {
            newSuggestions.append(WeatherSuggestion(title: "Low Visibility", description: "Foggy conditions. Drive carefully and avoid hiking on unfamiliar trails.", icon: "cloud.fog.fill", priority: .medium, type: .activity))
        }
        
        // Humidity
        if weather.humidity > 80 {
            newSuggestions.append(WeatherSuggestion(title: "High Humidity", description: "Humidity is \(Int(weather.humidity))%. Wear moisture-wicking fabrics.", icon: "humidity.fill", priority: .medium, type: .clothing))
        }
        
        // Best sightseeing suggestion
        let goodDays = forecast.enumerated().filter { (_, f) in
            let c = f.condition.lowercased()
            return (c.contains("clear") || c.contains("sunny") || c.contains("mainly clear")) && f.high > 15 && f.high < 32
        }
        if !goodDays.isEmpty {
            let dayNumbers = goodDays.prefix(3).map { "Day \($0.offset + 1)" }.joined(separator: ", ")
            newSuggestions.append(WeatherSuggestion(title: "Best for Sightseeing", description: "\(dayNumbers) have the best weather for outdoor activities.", icon: "figure.walk", priority: .medium, type: .activity))
        }
        
        // Comfortable shoes always
        newSuggestions.append(WeatherSuggestion(title: "Comfortable Shoes", description: "Pack your most comfortable walking shoes for exploring.", icon: "shoe.fill", priority: .medium, type: .clothing))
        
        suggestions = newSuggestions
    }
}
