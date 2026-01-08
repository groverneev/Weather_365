import Foundation
import WeatherKit

// MARK: - Weather Display Model (for UI)
struct WeatherDisplay: Identifiable, Equatable {
    let id = UUID()

    static func == (lhs: WeatherDisplay, rhs: WeatherDisplay) -> Bool {
        return lhs.cityName == rhs.cityName &&
               lhs.temperature == rhs.temperature &&
               lhs.humidity == rhs.humidity
    }

    let cityName: String
    let temperature: Double // In Celsius
    let feelsLike: Double
    let highTemp: Double
    let lowTemp: Double
    let humidity: Int
    let airQualityIndex: Int // Air Quality Index (1-5 scale)
    let windSpeed: Double
    let windDirection: Int
    let description: String
    let icon: String // SF Symbol name
    let sunrise: Date
    let sunset: Date
    let timezoneOffset: Int // Timezone offset in seconds from UTC

    // Initialize from WeatherKit CurrentWeather
    init(from currentWeather: CurrentWeather, cityName: String, timezoneOffset: Int) {
        self.cityName = cityName
        // WeatherKit returns temperature in the user's preferred unit, convert to Celsius
        self.temperature = currentWeather.temperature.converted(to: .celsius).value
        self.feelsLike = currentWeather.apparentTemperature.converted(to: .celsius).value
        // For current weather, use the same temp for high/low (daily forecast has actual high/low)
        self.highTemp = self.temperature
        self.lowTemp = self.temperature
        self.humidity = Int(currentWeather.humidity * 100)
        self.airQualityIndex = 3 // Default - WeatherKit doesn't provide AQI directly
        self.windSpeed = currentWeather.wind.speed.converted(to: .metersPerSecond).value
        self.windDirection = Int(currentWeather.wind.direction.value)
        self.description = currentWeather.condition.description
        self.icon = currentWeather.symbolName
        self.timezoneOffset = timezoneOffset

        // Get sunrise/sunset from the current date's sun events if available
        // Note: These will be set to current time as placeholder - actual sun times need daily forecast
        let now = Date()
        self.sunrise = now
        self.sunset = now
    }

    // Initialize from WeatherKit CurrentWeather with daily forecast for accurate high/low and sun times
    init(from currentWeather: CurrentWeather, dayWeather: DayWeather?, cityName: String, timezoneOffset: Int) {
        self.cityName = cityName
        self.temperature = currentWeather.temperature.converted(to: .celsius).value
        self.feelsLike = currentWeather.apparentTemperature.converted(to: .celsius).value

        if let day = dayWeather {
            self.highTemp = day.highTemperature.converted(to: .celsius).value
            self.lowTemp = day.lowTemperature.converted(to: .celsius).value
            self.sunrise = day.sun.sunrise ?? Date()
            self.sunset = day.sun.sunset ?? Date()
        } else {
            self.highTemp = self.temperature
            self.lowTemp = self.temperature
            self.sunrise = Date()
            self.sunset = Date()
        }

        self.humidity = Int(currentWeather.humidity * 100)
        self.airQualityIndex = 3 // Default
        self.windSpeed = currentWeather.wind.speed.converted(to: .metersPerSecond).value
        self.windDirection = Int(currentWeather.wind.direction.value)
        self.description = currentWeather.condition.description
        self.icon = currentWeather.symbolName
        self.timezoneOffset = timezoneOffset
    }

    // Custom initializer for previews and testing
    init(cityName: String, temperature: Double, feelsLike: Double, highTemp: Double, lowTemp: Double, humidity: Int, airQualityIndex: Int, windSpeed: Double, windDirection: Int, description: String, icon: String, sunrise: Date, sunset: Date, timezoneOffset: Int = 0) {
        self.cityName = cityName
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.highTemp = highTemp
        self.lowTemp = lowTemp
        self.humidity = humidity
        self.airQualityIndex = airQualityIndex
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.description = description
        self.icon = icon
        self.sunrise = sunrise
        self.sunset = sunset
        self.timezoneOffset = timezoneOffset
    }
}

// MARK: - Forecast Display Models
struct HourlyForecast: Identifiable {
    let id = UUID()
    let time: Date
    let temperature: Double // In Celsius
    let icon: String // SF Symbol name
    let description: String
    let isSunset: Bool
    let timezoneOffset: Int

    // Initialize from WeatherKit HourWeather
    init(from hourWeather: HourWeather, timezoneOffset: Int) {
        self.time = hourWeather.date
        self.temperature = hourWeather.temperature.converted(to: .celsius).value
        self.icon = hourWeather.symbolName
        self.description = hourWeather.condition.description
        self.timezoneOffset = timezoneOffset

        // Check if this is around sunset time (between 6 PM and 8 PM) using city time
        var calendar = Calendar.current
        if let cityTimezone = TimeZone(secondsFromGMT: timezoneOffset) {
            calendar.timeZone = cityTimezone
        }
        let hour = calendar.component(.hour, from: hourWeather.date)
        self.isSunset = hour >= 18 && hour <= 20
    }

    // Custom initializer for previews and testing
    init(time: Date, temperature: Double, icon: String, description: String, isSunset: Bool = false, timezoneOffset: Int = 0) {
        self.time = time
        self.temperature = temperature
        self.icon = icon
        self.description = description
        self.isSunset = isSunset
        self.timezoneOffset = timezoneOffset
    }
}

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let dayName: String
    let icon: String // SF Symbol name
    let lowTemp: Double // In Celsius
    let highTemp: Double // In Celsius
    let description: String

    // Initialize from WeatherKit DayWeather
    init(from dayWeather: DayWeather, timezoneOffset: Int, isToday: Bool = false) {
        self.date = dayWeather.date
        self.icon = dayWeather.symbolName
        self.lowTemp = dayWeather.lowTemperature.converted(to: .celsius).value
        self.highTemp = dayWeather.highTemperature.converted(to: .celsius).value
        self.description = dayWeather.condition.description

        // Get day name using the location's timezone
        var calendar = Calendar.current
        if let cityTimezone = TimeZone(secondsFromGMT: timezoneOffset) {
            calendar.timeZone = cityTimezone
        }

        if isToday {
            self.dayName = "Today"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            if let timezone = TimeZone(secondsFromGMT: timezoneOffset) {
                formatter.timeZone = timezone
            }
            self.dayName = formatter.string(from: dayWeather.date)
        }
    }

    // Custom initializer for previews and testing
    init(date: Date, dayName: String, icon: String, lowTemp: Double, highTemp: Double, description: String) {
        self.date = date
        self.dayName = dayName
        self.icon = icon
        self.lowTemp = lowTemp
        self.highTemp = highTemp
        self.description = description
    }
}

// MARK: - Temperature Conversion
extension Double {
    func toCelsius() -> Double {
        return self // Already in Celsius with WeatherKit
    }

    func toFahrenheit() -> Double {
        return self * 9/5 + 32
    }
}

// MARK: - Wind Direction Helper
extension Int {
    func windDirection() -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int(round(Double(self) / 22.5)) % 16
        return directions[index]
    }
}
