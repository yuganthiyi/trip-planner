import SwiftUI

// MARK: - Weather Suggestions View
struct WeatherSuggestionsView: View {
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HeaderView(title: "Weather Suggestions")
                    
                    // Content
                    ScrollView {
                        VStack(spacing: VoyaraTheme.spacing24) {
                            // Current Weather Section
                            if let weather = weatherViewModel.currentWeather {
                                CurrentWeatherCard(weather: weather)
                            }
                            
                            // Forecast Section
                            ForecastSection(forecast: weatherViewModel.forecast)
                            
                            // Suggestions Section
                            SuggestionsSection(suggestions: weatherViewModel.suggestions)
                        }
                        .padding(.horizontal, VoyaraTheme.spacing24)
                        .padding(.vertical, VoyaraTheme.spacing24)
                    }
                }
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
                    
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 50))
                        .foregroundColor(VoyaraColors.warning)
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
                
                Image(systemName: "cloud.fill")
                    .font(.system(size: 20))
                    .foregroundColor(VoyaraColors.primary.opacity(0.6))
                
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
