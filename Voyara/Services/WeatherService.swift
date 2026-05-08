import Foundation
import CoreLocation
import WeatherKit

// MARK: - Voyara Weather Service
// Uses Apple WeatherKit as primary, falls back to OpenMeteo free API
actor VoyaraWeatherService {
    static let shared = VoyaraWeatherService()
    
    private let geocoder = CLGeocoder()
    
    private init() {}
    
    // MARK: - Geocode destination string to coordinates
    func geocodeDestination(_ destination: String) async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(destination) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    continuation.resume(throwing: WeatherError.geocodingFailed)
                    return
                }
                continuation.resume(returning: location)
            }
        }
    }
    
    // MARK: - Reverse geocode coordinates to location name
    func reverseGeocode(_ location: CLLocation) async -> String {
        return await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? ""
                    let country = placemark.country ?? ""
                    let name = [city, country].filter { !$0.isEmpty }.joined(separator: ", ")
                    continuation.resume(returning: name.isEmpty ? "Current Location" : name)
                } else {
                    continuation.resume(returning: "Current Location")
                }
            }
        }
    }
    
    // MARK: - Fetch Weather (OpenWeather primary, then fallbacks)
    func fetchWeather(for location: CLLocation) async -> (current: WeatherInfo, forecast: [DailyForecast])? {
        // Try OpenWeather first (User provided key)
        if let result = await fetchOpenWeather(for: location) {
            return result
        }
        
        // Try WeatherKit second
        if let result = await fetchWeatherKit(for: location) {
            return result
        }
        
        // Final fallback to OpenMeteo
        return await fetchOpenMeteo(for: location)
    }
    
    // MARK: - OpenWeather (Primary)
    private func fetchOpenWeather(for location: CLLocation) async -> (current: WeatherInfo, forecast: [DailyForecast])? {
        let apiKey = "97beff1db70ca6e532113ea0cd315a31"
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        // We use the 5-day/3-hour forecast API as it's the most common free/standard API
        let urlString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&units=metric&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            
            // Parse Current (using first item in list)
            guard let list = json["list"] as? [[String: Any]], let first = list.first,
                  let main = first["main"] as? [String: Any],
                  let temp = main["temp"] as? Double,
                  let feelsLike = main["feels_like"] as? Double,
                  let humidity = main["humidity"] as? Double,
                  let wind = first["wind"] as? [String: Any],
                  let windSpeed = wind["speed"] as? Double,
                  let weatherArray = first["weather"] as? [[String: Any]],
                  let weather = weatherArray.first,
                  let condition = weather["main"] as? String else { return nil }
            
            let currentInfo = WeatherInfo(
                temperature: temp,
                feelsLike: feelsLike,
                condition: condition,
                humidity: humidity,
                windSpeed: windSpeed * 3.6, // Convert m/s to km/h
                uvIndex: 0, // Not provided by this API
                latitude: lat,
                longitude: lon
            )
            
            // Parse Forecast (group by day to get high/low)
            var dailyMap: [String: (high: Double, low: Double, condition: String)] = [:]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            for item in list {
                guard let dt = item["dt"] as? TimeInterval,
                      let m = item["main"] as? [String: Any],
                      let tMax = m["temp_max"] as? Double,
                      let tMin = m["temp_min"] as? Double,
                      let wArr = item["weather"] as? [[String: Any]],
                      let w = wArr.first,
                      let cond = w["main"] as? String else { continue }
                
                let date = Date(timeIntervalSince1970: dt)
                let dateKey = dateFormatter.string(from: date)
                
                if let existing = dailyMap[dateKey] {
                    dailyMap[dateKey] = (
                        high: max(existing.high, tMax),
                        low: min(existing.low, tMin),
                        condition: cond // Take the last one or most frequent
                    )
                } else {
                    dailyMap[dateKey] = (high: tMax, low: tMin, condition: cond)
                }
            }
            
            let sortedKeys = dailyMap.keys.sorted()
            let dailyForecast = sortedKeys.prefix(7).compactMap { key -> DailyForecast? in
                guard let data = dailyMap[key], let date = dateFormatter.date(from: key) else { return nil }
                return DailyForecast(day: date, high: data.high, low: data.low, condition: data.condition)
            }
            
            return (current: currentInfo, forecast: Array(dailyForecast))
            
        } catch {
            print("OpenWeather API failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - WeatherKit (Secondary Fallback)
    private func fetchWeatherKit(for location: CLLocation) async -> (current: WeatherInfo, forecast: [DailyForecast])? {
        do {
            let service = WeatherKit.WeatherService.shared
            let weather = try await service.weather(for: location)
            
            let currentInfo = WeatherInfo(
                temperature: weather.currentWeather.temperature.value,
                feelsLike: weather.currentWeather.apparentTemperature.value,
                condition: weather.currentWeather.condition.description,
                humidity: weather.currentWeather.humidity * 100,
                windSpeed: weather.currentWeather.wind.speed.value,
                uvIndex: Double(weather.currentWeather.uvIndex.value),
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            
            let dailyForecast = weather.dailyForecast.prefix(7).map { day in
                DailyForecast(
                    day: day.date,
                    high: day.highTemperature.value,
                    low: day.lowTemperature.value,
                    condition: day.condition.description
                )
            }
            
            return (current: currentInfo, forecast: Array(dailyForecast))
        } catch {
            print("WeatherKit failed: \(error.localizedDescription). Trying OpenMeteo...")
            return nil
        }
    }
    
    // MARK: - OpenMeteo Free API (No API key needed)
    private func fetchOpenMeteo(for location: CLLocation) async -> (current: WeatherInfo, forecast: [DailyForecast])? {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,uv_index&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto&forecast_days=7"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            
            // Parse current weather
            guard let current = json["current"] as? [String: Any],
                  let temp = current["temperature_2m"] as? Double,
                  let feelsLike = current["apparent_temperature"] as? Double,
                  let humidity = current["relative_humidity_2m"] as? Double,
                  let windSpeed = current["wind_speed_10m"] as? Double,
                  let weatherCode = current["weather_code"] as? Int else { return nil }
            
            let uvIndex = current["uv_index"] as? Double ?? 0
            
            let currentInfo = WeatherInfo(
                temperature: temp,
                feelsLike: feelsLike,
                condition: Self.weatherCodeToCondition(weatherCode),
                humidity: humidity,
                windSpeed: windSpeed,
                uvIndex: uvIndex,
                latitude: lat,
                longitude: lon
            )
            
            // Parse daily forecast
            var dailyForecasts: [DailyForecast] = []
            if let daily = json["daily"] as? [String: Any],
               let maxTemps = daily["temperature_2m_max"] as? [Double],
               let minTemps = daily["temperature_2m_min"] as? [Double],
               let codes = daily["weather_code"] as? [Int],
               let dates = daily["time"] as? [String] {
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                for i in 0..<min(maxTemps.count, 7) {
                    let date = dateFormatter.date(from: dates[i]) ?? Calendar.current.date(byAdding: .day, value: i, to: Date())!
                    dailyForecasts.append(DailyForecast(
                        day: date,
                        high: maxTemps[i],
                        low: minTemps[i],
                        condition: Self.weatherCodeToCondition(codes[i])
                    ))
                }
            }
            
            return (current: currentInfo, forecast: dailyForecasts)
        } catch {
            print("OpenMeteo API failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - WMO Weather Code to Condition String
    static func weatherCodeToCondition(_ code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1: return "Mainly Clear"
        case 2: return "Partly Cloudy"
        case 3: return "Cloudy"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing Drizzle"
        case 61, 63: return "Light Rain"
        case 65: return "Heavy Rain"
        case 66, 67: return "Freezing Rain"
        case 71, 73: return "Light Snow"
        case 75: return "Heavy Snow"
        case 77: return "Snow"
        case 80, 81: return "Rain"
        case 82: return "Heavy Rain"
        case 85, 86: return "Snow"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm"
        default: return "Clear"
        }
    }
    
    // MARK: - Generate Weather-Based Activity Suggestions
    func generateActivities(for weather: WeatherInfo) -> [WeatherActivity] {
        var activities: [WeatherActivity] = []
        let temp = weather.temperature
        let condition = weather.condition.lowercased()
        let isRainy = condition.contains("rain") || condition.contains("drizzle")
        let isSnowy = condition.contains("snow")
        let isClear = condition.contains("clear") || condition.contains("sunny")
        let isCloudy = condition.contains("cloud") || condition.contains("overcast")
        
        // Outdoor activities for good weather
        if (isClear || isCloudy) && temp > 10 && temp < 35 {
            activities.append(WeatherActivity(
                title: "Sightseeing Walk",
                description: "Perfect conditions for exploring on foot. Temperature is comfortable at \(Int(temp))°C.",
                icon: "figure.walk",
                category: .sightseeing,
                suitableConditions: ["Clear", "Partly Cloudy", "Mainly Clear"],
                temperatureRange: 10...35,
                isOutdoor: true
            ))
            activities.append(WeatherActivity(
                title: "Outdoor Café",
                description: "Great weather to enjoy local cuisine at an outdoor restaurant.",
                icon: "cup.and.saucer.fill",
                category: .dining,
                suitableConditions: ["Clear", "Partly Cloudy"],
                temperatureRange: 15...30,
                isOutdoor: true
            ))
        }
        
        if isClear && temp > 20 {
            activities.append(WeatherActivity(
                title: "Beach & Water Sports",
                description: "Warm and sunny — ideal for beach activities and water sports.",
                icon: "figure.surfing",
                category: .outdoor,
                suitableConditions: ["Clear", "Sunny"],
                temperatureRange: 20...40,
                isOutdoor: true
            ))
            activities.append(WeatherActivity(
                title: "Park & Gardens",
                description: "Beautiful day to visit parks and botanical gardens.",
                icon: "leaf.fill",
                category: .outdoor,
                suitableConditions: ["Clear", "Partly Cloudy"],
                temperatureRange: 18...32,
                isOutdoor: true
            ))
        }
        
        // Indoor activities for bad weather
        if isRainy || isSnowy {
            activities.append(WeatherActivity(
                title: "Museum Visit",
                description: "Weather outside isn't great. Perfect time to explore museums and galleries.",
                icon: "building.columns.fill",
                category: .culture,
                suitableConditions: ["Rain", "Snow", "Drizzle"],
                temperatureRange: -10...40,
                isOutdoor: false
            ))
            activities.append(WeatherActivity(
                title: "Indoor Shopping",
                description: "Stay dry and browse local shops, markets, and malls.",
                icon: "bag.fill",
                category: .shopping,
                suitableConditions: ["Rain", "Snow"],
                temperatureRange: -10...40,
                isOutdoor: false
            ))
            activities.append(WeatherActivity(
                title: "Spa & Wellness",
                description: "Rainy weather is perfect for a relaxing spa experience.",
                icon: "figure.mind.and.body",
                category: .wellness,
                suitableConditions: ["Rain", "Snow", "Fog"],
                temperatureRange: -10...40,
                isOutdoor: false
            ))
        }
        
        if isRainy {
            activities.append(WeatherActivity(
                title: "Local Cooking Class",
                description: "Learn to make local dishes — a great indoor activity on a rainy day.",
                icon: "fork.knife",
                category: .dining,
                suitableConditions: ["Rain", "Drizzle"],
                temperatureRange: -10...40,
                isOutdoor: false
            ))
        }
        
        // Cold weather
        if temp < 5 {
            activities.append(WeatherActivity(
                title: "Hot Springs / Thermal Bath",
                description: "Cold outside (\(Int(temp))°C). Warm up in a local thermal bath or hot spring.",
                icon: "drop.fill",
                category: .wellness,
                suitableConditions: ["Any"],
                temperatureRange: -20...10,
                isOutdoor: false
            ))
        }
        
        // Hot weather
        if temp > 30 {
            activities.append(WeatherActivity(
                title: "Indoor Attractions",
                description: "Very hot (\(Int(temp))°C). Visit air-conditioned attractions and entertainment.",
                icon: "building.2.fill",
                category: .entertainment,
                suitableConditions: ["Any"],
                temperatureRange: 30...50,
                isOutdoor: false
            ))
        }
        
        // Always available
        activities.append(WeatherActivity(
            title: "Local Food Tour",
            description: "Explore the local culinary scene regardless of weather.",
            icon: "fork.knife",
            category: .dining,
            suitableConditions: ["Any"],
            temperatureRange: -10...50,
            isOutdoor: false
        ))
        
        if activities.count < 3 {
            activities.append(WeatherActivity(
                title: "City Exploration",
                description: "Discover hidden gems and local neighborhoods.",
                icon: "map.fill",
                category: .sightseeing,
                suitableConditions: ["Any"],
                temperatureRange: -10...40,
                isOutdoor: true
            ))
        }
        
        return activities
    }
}

// MARK: - Weather Errors
enum WeatherError: Error, LocalizedError {
    case geocodingFailed
    case noData
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .geocodingFailed: return "Could not find location coordinates"
        case .noData: return "No weather data available"
        case .apiError(let msg): return msg
        }
    }
}
