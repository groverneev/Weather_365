import SwiftUI

struct WeatherView: View {
    let weather: WeatherDisplay
    let isCelsius: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var weatherService: WeatherService
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // City name and current temperature
                VStack(spacing: 15) {
                    Text(weather.cityName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Centered main temperature
                    Text("\(isCelsius ? weather.temperature : weather.temperature.toFahrenheit(), specifier: "%.0f")°")
                        .font(.system(size: 80, weight: .thin, design: .default))
                        .fontWeight(.thin)
                        .multilineTextAlignment(.center)
                    
                    // Weather description below temperature
                    Text(weather.description.capitalized)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Hourly Forecast Section
                if !weatherService.hourlyForecasts.isEmpty {
                    HourlyForecastView(forecasts: weatherService.hourlyForecasts, isCelsius: isCelsius)
                        .environmentObject(themeManager)
                }
                
                if horizontalSizeClass == .regular {
                    // iPad Layout: Daily Forecast and Details side-by-side
                    HStack(alignment: .top, spacing: 20) {
                        // Daily Forecast Section
                        if !weatherService.dailyForecasts.isEmpty {
                            DailyForecastView(forecasts: weatherService.dailyForecasts, isCelsius: isCelsius)
                                .environmentObject(themeManager)
                                .frame(maxWidth: 350) // Limit width for readability
                        }
                        
                        // Details Grid
                        VStack(spacing: 20) {
                            weatherDetailsGrid
                            
                            // Sunrise and Sunset
                            sunriseSunsetView
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    // iPhone Layout: Vertical stack
                    if !weatherService.dailyForecasts.isEmpty {
                        DailyForecastView(forecasts: weatherService.dailyForecasts, isCelsius: isCelsius)
                            .environmentObject(themeManager)
                    }
                    
                    // Details Grid
                    weatherDetailsGrid
                        .padding(.horizontal, 20)
                    
                    // Sunrise and Sunset
                    sunriseSunsetView
                        .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 20)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private var weatherDetailsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 20)], spacing: 20) {
            // High temperature
            WeatherDetailCard(
                icon: "thermometer.sun.fill",
                title: "High",
                value: String(format: "%.0f°", isCelsius ? weather.highTemp : weather.highTemp.toFahrenheit()),
                color: .red
            )
            
            // Low temperature
            WeatherDetailCard(
                icon: "thermometer.snowflake",
                title: "Low",
                value: String(format: "%.0f°", isCelsius ? weather.lowTemp : weather.lowTemp.toFahrenheit()),
                color: .blue
            )
            
            // Humidity
            WeatherDetailCard(
                icon: "humidity",
                title: "Humidity",
                value: "\(weather.humidity)%",
                color: .blue
            )
            
            // Air Quality
            WeatherDetailCard(
                icon: airQualityIcon,
                title: "Air Quality",
                value: airQualityText,
                color: airQualityColor
            )
            
            // Feels Like
            WeatherDetailCard(
                icon: "thermometer",
                title: "Feels Like",
                value: String(format: "%.0f°", isCelsius ? weather.feelsLike : weather.feelsLike.toFahrenheit()),
                color: .orange
            )
            
            // Wind Speed
            WeatherDetailCard(
                icon: "wind",
                title: "Wind Speed",
                value: String(format: "%.1f m/s", weather.windSpeed),
                color: .cyan
            )
            
            // Wind Direction
            WeatherDetailCard(
                icon: "location.north",
                title: "Wind Direction",
                value: weather.windDirection.windDirection(),
                color: .purple
            )
        }
    }
    
    private var sunriseSunsetView: some View {
        HStack(spacing: 40) {
            VStack {
                Image(systemName: "sunrise")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Sunrise")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(weather.sunrise, style: .time)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .environment(\.timeZone, TimeZone(secondsFromGMT: weather.timezoneOffset) ?? TimeZone.current)
            }
            
            VStack {
                Image(systemName: "sunset")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Sunset")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(weather.sunset, style: .time)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .environment(\.timeZone, TimeZone(secondsFromGMT: weather.timezoneOffset) ?? TimeZone.current)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 40)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(15)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var airQualityIcon: String {
        switch weather.airQualityIndex {
        case 1:
            return "leaf.fill"
        case 2:
            return "leaf"
        case 3:
            return "exclamationmark.triangle"
        case 4:
            return "exclamationmark.triangle.fill"
        case 5:
            return "xmark.octagon.fill"
        default:
            return "questionmark.circle"
        }
    }
    
    private var airQualityColor: Color {
        switch weather.airQualityIndex {
        case 1:
            return .green
        case 2:
            return .yellow
        case 3:
            return .orange
        case 4:
            return .red
        case 5:
            return .purple
        default:
            return .gray
        }
    }
    
    private var airQualityText: String {
        switch weather.airQualityIndex {
        case 1:
            return "Good"
        case 2:
            return "Fair"
        case 3:
            return "Moderate"
        case 4:
            return "Poor"
        case 5:
            return "Very Poor"
        default:
            return "Unknown"
        }
    }
}

struct WeatherDetailCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.8) : .secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? .white : .primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(themeManager.isDarkMode ? Color(.systemGray5) : Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(color: themeManager.isDarkMode ? .clear : .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    let sampleWeather = WeatherDisplay(
        cityName: "San Francisco",
        temperature: 293.15,
        feelsLike: 291.15,
        highTemp: 298.15,
        lowTemp: 288.15,
        humidity: 65,
        airQualityIndex: 2,
        windSpeed: 5.2,
        windDirection: 180,
        description: "partly cloudy",
        icon: "02d",
        sunrise: Date(),
        sunset: Date().addingTimeInterval(3600 * 12),
        timezoneOffset: -28800 // Pacific Time (UTC-8)
    )
    
    let themeManager = ThemeManager()
    let weatherService = WeatherService()
    
    WeatherView(weather: sampleWeather, isCelsius: true)
        .environmentObject(themeManager)
        .environmentObject(weatherService)
}
