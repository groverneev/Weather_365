import Foundation

// MARK: - Weather Response Models
struct WeatherResponse: Codable {
    let coord: Coordinates
    let weather: [Weather]
    let base: String
    let main: MainWeather
    let visibility: Int
    let wind: Wind
    let clouds: Clouds
    let dt: Int
    let sys: System
    let timezone: Int
    let id: Int
    let name: String
    let cod: Int
}

struct Coordinates: Codable {
    let lon: Double
    let lat: Double
}

struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct MainWeather: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int
    let humidity: Int
    let seaLevel: Int?
    let grndLevel: Int?
    
    enum CodingKeys: String, CodingKey {
        case temp, pressure, humidity
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case seaLevel = "sea_level"
        case grndLevel = "grnd_level"
    }
}

struct Wind: Codable {
    let speed: Double
    let deg: Int
    let gust: Double?
}

struct Clouds: Codable {
    let all: Int
}

struct System: Codable {
    let type: Int?
    let id: Int?
    let country: String
    let sunrise: Int
    let sunset: Int
}

// MARK: - Weather Display Model (for UI)
struct WeatherDisplay: Identifiable, Equatable {
    let id = UUID() // Add unique identifier for sheet presentation

    static func == (lhs: WeatherDisplay, rhs: WeatherDisplay) -> Bool {
        // Compare by city name and temperature for practical equality
        // (different fetches for same city should be considered equal for UI purposes)
        return lhs.cityName == rhs.cityName &&
               lhs.temperature == rhs.temperature &&
               lhs.humidity == rhs.humidity
    }
    let cityName: String
    let temperature: Double
    let feelsLike: Double
    let highTemp: Double
    let lowTemp: Double
    let humidity: Int
    let airQualityIndex: Int // Air Quality Index (1-5 scale)
    let windSpeed: Double
    let windDirection: Int
    let description: String
    let icon: String
    let sunrise: Date
    let sunset: Date
    let timezoneOffset: Int // Timezone offset in seconds from UTC
    
    init(from response: WeatherResponse) {
        self.cityName = response.name
        self.temperature = response.main.temp
        self.feelsLike = response.main.feelsLike
        self.highTemp = response.main.tempMax
        self.lowTemp = response.main.tempMin
        self.humidity = response.main.humidity
        self.airQualityIndex = 3 // Default value, will be updated by separate API call
        self.windSpeed = response.wind.speed
        self.windDirection = response.wind.deg
        self.description = response.weather.first?.description ?? ""
        self.icon = response.weather.first?.icon ?? ""
        self.timezoneOffset = response.timezone
        
        // Convert UTC times to city's local timezone
        let _ = TimeZone(secondsFromGMT: response.timezone) ?? TimeZone.current
        self.sunrise = Date(timeIntervalSince1970: TimeInterval(response.sys.sunrise))
        self.sunset = Date(timeIntervalSince1970: TimeInterval(response.sys.sunset))
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

// MARK: - Forecast Models
struct ForecastResponse: Codable {
    let list: [ForecastItem]
    let city: ForecastCity
}

struct ForecastItem: Codable {
    let dt: Int
    let main: ForecastMain
    let weather: [Weather]
    let clouds: Clouds
    let wind: Wind
    let visibility: Int
    let pop: Double
    let sys: ForecastSys
    let dtTxt: String
    
    enum CodingKeys: String, CodingKey {
        case dt, main, weather, clouds, wind, visibility, pop, sys
        case dtTxt = "dt_txt"
    }
}

struct ForecastMain: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int
    let humidity: Int
    let seaLevel: Int?
    let grndLevel: Int?
    
    enum CodingKeys: String, CodingKey {
        case temp, pressure, humidity
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case seaLevel = "sea_level"
        case grndLevel = "grnd_level"
    }
}

struct ForecastSys: Codable {
    let pod: String // Part of day: "d" for day, "n" for night
}

struct ForecastCity: Codable {
    let id: Int
    let name: String
    let coord: Coordinates
    let country: String
    let population: Int
    let timezone: Int
    let sunrise: Int
    let sunset: Int
}

// MARK: - Forecast Display Models
struct HourlyForecast: Identifiable {
    let id = UUID()
    let time: Date
    let temperature: Double
    let icon: String
    let description: String
    let isSunset: Bool
    let timezoneOffset: Int // Store timezone offset for proper time display
    
    init(from forecastItem: ForecastItem, timezoneOffset: Int) {
        // Create time in the city's timezone, not UTC
        let utcTime = Date(timeIntervalSince1970: TimeInterval(forecastItem.dt))
        
        // Apply timezone offset to get city-local time
        if let cityTimezone = TimeZone(secondsFromGMT: timezoneOffset) {
            var calendar = Calendar.current
            calendar.timeZone = cityTimezone
            self.time = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: utcTime)) ?? utcTime
        } else {
            self.time = utcTime
        }
        
        self.temperature = forecastItem.main.temp
        self.icon = forecastItem.weather.first?.icon ?? ""
        self.description = forecastItem.weather.first?.description ?? ""
        self.timezoneOffset = timezoneOffset
        
        // Check if this is around sunset time (between 6 PM and 8 PM) using city time
        var calendar = Calendar.current
        if let cityTimezone = TimeZone(secondsFromGMT: timezoneOffset) {
            calendar.timeZone = cityTimezone
        }
        let hour = calendar.component(.hour, from: self.time)
        self.isSunset = hour >= 18 && hour <= 20
    }
}

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let dayName: String
    let icon: String
    let lowTemp: Double
    let highTemp: Double
    let description: String
    
    init(from forecastItems: [ForecastItem], timezoneOffset: Int) {
        // Group forecast items by day and calculate daily min/max
        var cityCalendar = Calendar.current
        
        // Set the calendar to use the city's timezone
        if let cityTimezone = TimeZone(secondsFromGMT: timezoneOffset) {
            cityCalendar.timeZone = cityTimezone
        }
        
        // Find the first forecast item for this day
        guard let firstItem = forecastItems.first else {
            self.date = Date()
            self.dayName = "Today"
            self.icon = ""
            self.lowTemp = 0
            self.highTemp = 0
            self.description = ""
            return
        }
        
        let date = Date(timeIntervalSince1970: TimeInterval(firstItem.dt))
        self.date = date
        
        // Get day name using the location's timezone
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        // Create timezone from the offset
        if let timezone = TimeZone(secondsFromGMT: timezoneOffset) {
            formatter.timeZone = timezone
        }
        
        // Determine if this is actually "today" in the city's timezone
        let cityToday = cityCalendar.startOfDay(for: Date())
        let forecastDay = cityCalendar.startOfDay(for: date)
        let isActuallyToday = cityCalendar.isDate(forecastDay, inSameDayAs: cityToday)
        
        // Show "Today" only if it's actually today in the city's timezone
        if isActuallyToday {
            self.dayName = "Today"
        } else {
            self.dayName = formatter.string(from: date)
        }
        
        // Use the first item's weather for icon and description
        self.icon = firstItem.weather.first?.icon ?? ""
        self.description = firstItem.weather.first?.description ?? ""
        
        // Calculate daily min/max from all items for this day using city timezone
        let dayItems = forecastItems.filter { item in
            let itemDate = Date(timeIntervalSince1970: TimeInterval(item.dt))
            return cityCalendar.isDate(itemDate, inSameDayAs: date)
        }
        
        // Calculate min/max temperatures
        let minTemp = dayItems.map({ $0.main.tempMin }).min() ?? firstItem.main.tempMin
        let maxTemp = dayItems.map({ $0.main.tempMax }).max() ?? firstItem.main.tempMax
        
        self.lowTemp = minTemp
        self.highTemp = maxTemp
    }
}

// MARK: - Temperature Conversion
extension Double {
    func toCelsius() -> Double {
        return self
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
