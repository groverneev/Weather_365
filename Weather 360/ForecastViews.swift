import SwiftUI

// MARK: - Hourly Forecast View
struct HourlyForecastView: View {
    let forecasts: [HourlyForecast]
    let isCelsius: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Hourly Forecast")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(forecasts) { forecast in
                        HourlyForecastItem(forecast: forecast, isCelsius: isCelsius)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct HourlyForecastItem: View {
    let forecast: HourlyForecast
    let isCelsius: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Time
            Text(timeString)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            // Weather Icon
            if forecast.isSunset {
                Image(systemName: "sunset.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            } else {
                WeatherIconView(iconCode: forecast.icon)
                    .frame(width: 30, height: 30)
            }
            
            // Temperature
            Text("\(isCelsius ? forecast.temperature : forecast.temperature.toFahrenheit(), specifier: "%.0f")°")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(width: 60)
        .padding(.vertical, 12)
        .background(themeManager.isDarkMode ? Color(.systemGray6) : Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: themeManager.isDarkMode ? .clear : .black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        formatter.locale = Locale(identifier: "en_US")
        
        // Use the city's timezone for proper time display
        if let cityTimezone = TimeZone(secondsFromGMT: forecast.timezoneOffset) {
            formatter.timeZone = cityTimezone
        }
        
        var calendar = Calendar.current
        if let cityTimezone = TimeZone(secondsFromGMT: forecast.timezoneOffset) {
            calendar.timeZone = cityTimezone
        }
        
        let hour = calendar.component(.hour, from: forecast.time)
        let currentHour = calendar.component(.hour, from: Date())
        
        if hour == currentHour {
            return "Now"
        } else {
            return formatter.string(from: forecast.time)
        }
    }
}

// MARK: - Daily Forecast View
struct DailyForecastView: View {
    let forecasts: [DailyForecast]
    let isCelsius: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("5-Day Forecast")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(forecasts) { forecast in
                    DailyForecastItem(forecast: forecast, isCelsius: isCelsius)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct DailyForecastItem: View {
    let forecast: DailyForecast
    let isCelsius: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 15) {
            // Day name
            Text(forecast.dayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 50, alignment: .leading)
            
            // Weather icon
            WeatherIconView(iconCode: forecast.icon)
                .frame(width: 25, height: 25)
            
            // Low temperature (left of bar)
            Text("\(isCelsius ? forecast.lowTemp : forecast.lowTemp.toFahrenheit(), specifier: "%.0f")°")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 35, alignment: .trailing)
            
            // Temperature range bar
            TemperatureRangeBar(
                lowTemp: forecast.lowTemp,
                highTemp: forecast.highTemp,
                isCelsius: isCelsius
            )
            
            // High temperature (right of bar)
            Text("\(isCelsius ? forecast.highTemp : forecast.highTemp.toFahrenheit(), specifier: "%.0f")°")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(width: 35, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 15)
        .background(themeManager.isDarkMode ? Color(.systemGray6) : Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: themeManager.isDarkMode ? .clear : .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Temperature Range Bar
struct TemperatureRangeBar: View {
    let lowTemp: Double
    let highTemp: Double
    let isCelsius: Bool
    
    private var temperatureColors: (start: Color, end: Color) {
        let avgTemp = (lowTemp + highTemp) / 2
        
        // Convert to Fahrenheit for color logic, but use Celsius ranges
        let tempInFahrenheit = isCelsius ? avgTemp * 9/5 + 32 : avgTemp
        
        switch tempInFahrenheit {
        case ..<10: // Below 10°C (50°F)
            return (.blue, .cyan) // Cold
        case 10..<18: // 10-18°C (50-65°F)
            return (.cyan, .green) // Cool
        case 18..<24: // 18-24°C (65-75°F)
            return (.green, .yellow) // Mild
        case 24..<30: // 24-30°C (75-85°F)
            return (.yellow, .orange) // Warm
        default: // Above 30°C (85°F)
            return (.orange, .red) // Hot
        }
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [temperatureColors.start, temperatureColors.end]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 8)
            .cornerRadius(4)
            .frame(height: 20)
    }
}
// MARK: - Weather Icon View
struct WeatherIconView: View {
    let iconCode: String // SF Symbol name from WeatherKit

    var body: some View {
        Image(systemName: iconCode)
            .symbolRenderingMode(.multicolor)
            .font(.title2)
    }
}

#Preview {
    VStack(spacing: 30) {
        HourlyForecastView(forecasts: [
            HourlyForecast(time: Date(), temperature: 20, icon: "sun.max.fill", description: "Clear", timezoneOffset: -28800),
            HourlyForecast(time: Date().addingTimeInterval(3600 * 3), temperature: 22, icon: "cloud.sun.fill", description: "Partly Cloudy", timezoneOffset: -28800)
        ], isCelsius: true)

        DailyForecastView(forecasts: [
            DailyForecast(date: Date(), dayName: "Today", icon: "sun.max.fill", lowTemp: 15, highTemp: 25, description: "Clear"),
            DailyForecast(date: Date().addingTimeInterval(86400), dayName: "Mon", icon: "cloud.sun.fill", lowTemp: 16, highTemp: 26, description: "Partly Cloudy")
        ], isCelsius: true)
    }
    .padding()
    .background(Color.blue.opacity(0.1))
    .environmentObject(ThemeManager())
}