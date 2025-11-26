# Weather 365 - iOS Weather App

A beautiful, modern iOS weather application built with SwiftUI that provides comprehensive weather information for any city worldwide.

## Features

- **City Search**: Enter any city name to get current weather conditions
- **Current Location**: Use GPS to get weather for your current location
- **Comprehensive Weather Data**: 
  - Current temperature (with Celsius/Fahrenheit toggle)
  - High and low temperatures
  - "Feels like" temperature
  - Humidity percentage
  - Atmospheric pressure
  - Wind speed and direction
  - Sunrise and sunset times
  - Weather description and conditions
- **Modern UI**: Beautiful, intuitive interface with smooth animations
- **Real-time Data**: Live weather information from OpenWeatherMap API

## Setup Instructions

### 1. Get OpenWeatherMap API Key

1. Visit [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Get your API key from the dashboard

### 2. Configure API Key

**Option A: Use Template (Recommended)**
1. Copy `Config.template.swift` from the root directory to `Weather 365/Config.swift`
2. Replace `"YOUR_API_KEY_HERE"` with your actual API key
3. The `Config.swift` file is already in `.gitignore` and won't be pushed to GitHub

**Option B: Manual Setup**
1. Create `Weather 365/Config.swift` file
2. Add your API key:
```swift
import Foundation

struct Config {
    static let openWeatherMapAPIKey = "YOUR_ACTUAL_API_KEY_HERE"
    static let openWeatherMapBaseURL = "https://api.openweathermap.org/data/2.5/weather"
    static let appName = "Weather 365"
    static let appVersion = "1.0.0"
}
```

### 3. Build and Run

1. Open `Weather 365.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project (⌘+R)

## Security Notes

- **Never commit API keys** to version control
- The `Config.swift` file is automatically excluded from Git
- Use `Config.template.swift` as a reference for setup
- Keep your API keys secure and private

## API Information

This app uses the OpenWeatherMap Current Weather Data API which returns:

- **Coordinates**: Latitude and longitude
- **Weather**: Main condition, description, and icon code
- **Main Weather Data**: Temperature, feels like, min/max, pressure, humidity
- **Wind**: Speed and direction
- **Clouds**: Cloud coverage percentage
- **System**: Country, sunrise, sunset times
- **Additional**: Visibility, timezone, city ID

## Technical Details

- **Framework**: SwiftUI
- **iOS Target**: iOS 15.0+
- **Architecture**: MVVM with ObservableObject
- **Networking**: URLSession with async/await pattern
- **Location**: CoreLocation for GPS access
- **Data Models**: Codable structs for API responses

## File Structure

- `WeatherModels.swift` - Data models and extensions
- `WeatherService.swift` - API service and location manager
- `WeatherView.swift` - Main weather display interface
- `SearchView.swift` - City search and location functionality
- `ContentView.swift` - Main app container
- `Weather_365App.swift` - App entry point

## Permissions

The app requires location access permissions to provide weather for your current location. These are configured in `Info.plist`.

## Customization

You can easily customize:
- Temperature units (Celsius/Fahrenheit)
- UI colors and styling
- Additional weather data fields
- API endpoints for different weather services

## Troubleshooting

- **API Key Issues**: Ensure your OpenWeatherMap API key is valid and has proper permissions
- **Location Access**: Check that location permissions are granted in iOS Settings
- **Network Issues**: Verify internet connectivity and API endpoint accessibility

## License

This project is for educational purposes. Please respect OpenWeatherMap's terms of service for API usage.
