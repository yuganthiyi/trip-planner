import SwiftUI
import MapKit

// MARK: - Weather Suggestions View
struct WeatherSuggestionsView: View {
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    @State private var destinationSearch = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HeaderView(title: "Weather & Activities")
                    
                    // Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: VoyaraTheme.spacing24) {
                            // Destination Search
                            destinationSearchBar
                            
                            // Location Label
                            if !weatherViewModel.locationName.isEmpty {
                                HStack(spacing: VoyaraTheme.spacing8) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(VoyaraColors.primary)
                                    Text(weatherViewModel.locationName)
                                        .font(VoyaraTypography.labelMedium)
                                        .foregroundColor(VoyaraColors.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, VoyaraTheme.spacing24)
                            }
                            
                            // Current Weather Section
                            if weatherViewModel.isLoading {
                                VoyaraCard {
                                    HStack {
                                        ProgressView()
                                        Text("Fetching weather data...")
                                            .font(VoyaraTypography.bodyMedium)
                                            .foregroundColor(VoyaraColors.textSecondary)
                                            .padding(.leading, VoyaraTheme.spacing8)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(VoyaraTheme.spacing16)
                                }
                                .padding(.horizontal, VoyaraTheme.spacing24)
                            } else if let weather = weatherViewModel.currentWeather {
                                CurrentWeatherCard(weather: weather)
                                    .padding(.horizontal, VoyaraTheme.spacing24)
                                
                                // Mini Map
                                weatherMapSection(weather: weather)
                            }
                            
                            // Weather-Based Activities
                            if !weatherViewModel.weatherActivities.isEmpty {
                                weatherActivitiesSection
                            }
                            
                            // Forecast Section
                            if !weatherViewModel.forecast.isEmpty {
                                ForecastSection(forecast: weatherViewModel.forecast)
                                    .padding(.horizontal, VoyaraTheme.spacing24)
                            }
                            
                            // Suggestions Section
                            if !weatherViewModel.suggestions.isEmpty {
                                SuggestionsSection(suggestions: weatherViewModel.suggestions)
                                    .padding(.horizontal, VoyaraTheme.spacing24)
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.vertical, VoyaraTheme.spacing16)
                    }
                }
            }
        }
    }
    
    // MARK: - Destination Search Bar
    private var destinationSearchBar: some View {
        HStack(spacing: VoyaraTheme.spacing12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(VoyaraColors.textSecondary)
            
            TextField("Search any destination for weather...", text: $destinationSearch)
                .font(VoyaraTypography.bodyMedium)
                .foregroundColor(VoyaraColors.text)
                .onSubmit {
                    if !destinationSearch.isEmpty {
                        weatherViewModel.fetchWeather(for: destinationSearch)
                    }
                }
            
            if !destinationSearch.isEmpty {
                Button(action: {
                    destinationSearch = ""
                    // Refresh to current location
                    weatherViewModel.fetchWeather()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(VoyaraColors.textSecondary)
                }
            }
            
            Button(action: {
                if !destinationSearch.isEmpty {
                    weatherViewModel.fetchWeather(for: destinationSearch)
                }
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(destinationSearch.isEmpty ? VoyaraColors.textSecondary : VoyaraColors.primary)
            }
            .disabled(destinationSearch.isEmpty)
        }
        .padding(VoyaraTheme.spacing12)
        .background(VoyaraColors.surfaceVariant)
        .cornerRadius(VoyaraTheme.mediumRadius)
        .padding(.horizontal, VoyaraTheme.spacing24)
    }
    
    // MARK: - Weather Map Section
    private func weatherMapSection(weather: WeatherInfo) -> some View {
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
            SectionHeader(title: "Weather Location")
                .padding(.horizontal, VoyaraTheme.spacing24)
            
            if let lat = weather.latitude, let lon = weather.longitude {
                Map {
                    Annotation(
                        weatherViewModel.locationName,
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    ) {
                        VStack(spacing: 2) {
                            ZStack {
                                Circle()
                                    .fill(weather.conditionColor.opacity(0.9))
                                    .frame(width: 40, height: 40)
                                
                                VStack(spacing: 0) {
                                    Image(systemName: weather.conditionIcon)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    Text("\(Int(weather.temperature))°")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .shadow(radius: 4)
                            
                            Image(systemName: "triangle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(weather.conditionColor.opacity(0.9))
                                .rotationEffect(.degrees(180))
                                .offset(y: -4)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .frame(height: 180)
                .cornerRadius(VoyaraTheme.cornerRadius)
                .padding(.horizontal, VoyaraTheme.spacing24)
            }
        }
    }
    
    // MARK: - Weather Activities Section
    private var weatherActivitiesSection: some View {
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
            SectionHeader(title: "Suggested Activities")
                .padding(.horizontal, VoyaraTheme.spacing24)
            
            Text("Based on current weather conditions")
                .font(VoyaraTypography.bodySmall)
                .foregroundColor(VoyaraColors.textSecondary)
                .padding(.horizontal, VoyaraTheme.spacing24)
            
            ForEach(weatherViewModel.weatherActivities) { activity in
                VoyaraCard {
                    HStack(spacing: VoyaraTheme.spacing12) {
                        Image(systemName: activity.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
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
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        (activity.isOutdoor ? VoyaraColors.success : VoyaraColors.primary).opacity(0.12)
                                    )
                                    .cornerRadius(8)
                            }
                            
                            Text(activity.description)
                                .font(VoyaraTypography.bodySmall)
                                .foregroundColor(VoyaraColors.textSecondary)
                                .lineLimit(2)
                            
                            Text(activity.category.rawValue)
                                .font(VoyaraTypography.captionSmall)
                                .foregroundColor(activity.category.color)
                        }
                    }
                }
                .padding(.horizontal, VoyaraTheme.spacing24)
            }
        }
    }
}

// MARK: - Current Weather Card
struct CurrentWeatherCard: View {
    let weather: WeatherInfo
    
    var body: some View {
        VoyaraCard {
            VStack(spacing: VoyaraTheme.spacing20) {
                HStack(spacing: VoyaraTheme.spacing20) {
                    VStack(alignment: .leading, spacing: VoyaraTheme.spacing8) {
                        Text(weather.condition)
                            .font(VoyaraTypography.headlineSmall)
                            .foregroundColor(VoyaraColors.text)
                        
                        HStack(spacing: VoyaraTheme.spacing4) {
                            Text("\(Int(weather.temperature))°C")
                                .font(VoyaraTypography.displayLarge)
                                .foregroundColor(VoyaraColors.text)
                            
                            Text("feels like \(Int(weather.feelsLike))°")
                                .font(VoyaraTypography.bodySmall)
                                .foregroundColor(VoyaraColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: weather.conditionIcon)
                        .font(.system(size: 50))
                        .foregroundColor(weather.conditionColor)
                }
                
                Divider()
                    .background(VoyaraColors.divider)
                
                // Weather Details
                HStack(spacing: VoyaraTheme.spacing16) {
                    WeatherDetailItem(
                        icon: "drop.fill",
                        label: "Humidity",
                        value: "\(Int(weather.humidity))%"
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(VoyaraColors.divider)
                    
                    WeatherDetailItem(
                        icon: "wind",
                        label: "Wind",
                        value: "\(Int(weather.windSpeed)) km/h"
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(VoyaraColors.divider)
                    
                    WeatherDetailItem(
                        icon: "sun.max",
                        label: "UV Index",
                        value: "\(Int(weather.uvIndex))"
                    )
                }
            }
        }
    }
}

// MARK: - Weather Detail Item
struct WeatherDetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .center, spacing: VoyaraTheme.spacing4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(VoyaraColors.primary)
            
            Text(label)
                .font(VoyaraTypography.labelSmall)
                .foregroundColor(VoyaraColors.textSecondary)
            
            Text(value)
                .font(VoyaraTypography.bodyMedium)
                .foregroundColor(VoyaraColors.text)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Forecast Section
struct ForecastSection: View {
    let forecast: [DailyForecast]
    
    var body: some View {
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
            Text("7-Day Forecast")
                .font(VoyaraTypography.headlineMedium)
                .foregroundColor(VoyaraColors.text)
            
            VStack(spacing: VoyaraTheme.spacing8) {
                ForEach(forecast.prefix(7)) { day in
                    ForecastDayRow(forecast: day)
                }
            }
        }
    }
}

// MARK: - Forecast Day Row
struct ForecastDayRow: View {
    let forecast: DailyForecast
    
    var body: some View {
        VoyaraCard {
            HStack(spacing: VoyaraTheme.spacing12) {
                VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                    Text(forecast.day.formatted(.dateTime.weekday(.abbreviated)))
                        .font(VoyaraTypography.bodyMedium)
                        .foregroundColor(VoyaraColors.text)
                    
                    Text(forecast.day.formatted(.dateTime.month(.abbreviated).day()))
                        .font(VoyaraTypography.labelSmall)
                        .foregroundColor(VoyaraColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: forecast.conditionIcon)
                    .font(.system(size: 20))
                    .foregroundColor(forecast.conditionColor)
                
                VStack(alignment: .trailing, spacing: VoyaraTheme.spacing4) {
                    HStack(spacing: VoyaraTheme.spacing4) {
                        Text("\(Int(forecast.high))°")
                            .font(VoyaraTypography.bodyMedium)
                            .foregroundColor(VoyaraColors.text)
                        
                        Text("\(Int(forecast.low))°")
                            .font(VoyaraTypography.bodySmall)
                            .foregroundColor(VoyaraColors.textSecondary)
                    }
                    
                    Text(forecast.condition)
                        .font(VoyaraTypography.labelSmall)
                        .foregroundColor(VoyaraColors.textSecondary)
                }
            }
            .padding(VoyaraTheme.spacing12)
        }
    }
}

// MARK: - Suggestions Section
struct SuggestionsSection: View {
    let suggestions: [WeatherSuggestion]
    
    var body: some View {
        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
            Text("Recommendations")
                .font(VoyaraTypography.headlineMedium)
                .foregroundColor(VoyaraColors.text)
            
            VStack(spacing: VoyaraTheme.spacing12) {
                ForEach(suggestions) { suggestion in
                    SuggestionCard(suggestion: suggestion)
                }
            }
        }
    }
}

// MARK: - Suggestion Card
struct SuggestionCard: View {
    let suggestion: WeatherSuggestion
    
    var body: some View {
        VoyaraCard {
            HStack(spacing: VoyaraTheme.spacing12) {
                Image(systemName: suggestion.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(VoyaraColors.primary)
                    .frame(width: 40, height: 40)
                    .background(VoyaraColors.primary.opacity(0.1))
                    .cornerRadius(VoyaraTheme.mediumRadius)
                
                VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                    HStack {
                        Text(suggestion.title)
                            .font(VoyaraTypography.bodyMedium)
                            .foregroundColor(VoyaraColors.text)
                        
                        Spacer()
                        
                        Label(suggestion.priority == .high ? "High" : suggestion.priority == .medium ? "Medium" : "Low", 
                              systemImage: "dot.fill")
                            .font(VoyaraTypography.labelSmall)
                            .foregroundColor(priorityColor(suggestion.priority))
                    }
                    
                    Text(suggestion.description)
                        .font(VoyaraTypography.bodySmall)
                        .foregroundColor(VoyaraColors.textSecondary)
                        .lineLimit(2)
                }
            }
        }
    }
    
    func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high: return VoyaraColors.error
        case .medium: return VoyaraColors.warning
        case .low: return VoyaraColors.success
        }
    }
}

#Preview {
    WeatherSuggestionsView()
        .environmentObject(WeatherViewModel())
}
