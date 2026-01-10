import Foundation
import Combine
import os.log
import Network
import CoreLocation
import WeatherKit

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false

    init() {
        // Check if user has set a preference
        if let savedTheme = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool {
            isDarkMode = savedTheme
        } else {
            // Default to light mode
            isDarkMode = false
        }
    }

    func toggleTheme() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
}

// MARK: - Weather Service
class WeatherService: ObservableObject {
    @Published var weather: WeatherDisplay?
    @Published var hourlyForecasts: [HourlyForecast] = []
    @Published var dailyForecasts: [DailyForecast] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let weatherService = WeatherKit.WeatherService.shared
    private let logger = Logger(subsystem: "com.weatherapp", category: "WeatherService")
    private let networkMonitor = NWPathMonitor()
    private var isNetworkReachable = false
    private let geocoder = CLGeocoder()
    let locationManager = LocationManager()

    init() {
        // Setup network monitoring
        setupNetworkMonitoring()

        // Connect location updates to weather fetching
        locationManager.onLocationReceived = { [weak self] location in
            print("📍 [DEBUG] WeatherService: Location received, fetching weather...")
            self?.fetchWeatherByCoordinates(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
    }

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkReachable = path.status == .satisfied
                print("🌐 [DEBUG] Network status: \(path.status)")
                print("🌐 [DEBUG] Network reachable: \(self?.isNetworkReachable ?? false)")
            }
        }
        networkMonitor.start(queue: DispatchQueue.global())
    }

    // MARK: - Fetch Weather by City Name
    func fetchWeather(for city: String) {
        print("\n" + String(repeating: "=", count: 50))
        print("🚀 [DEBUG] STARTING NEW WEATHER REQUEST (WeatherKit)")
        print(String(repeating: "=", count: 50))

        isLoading = true
        errorMessage = nil

        // Check network connectivity first
        guard isNetworkReachable else {
            print("❌ [DEBUG] Network is not reachable!")
            errorMessage = "No internet connection available"
            isLoading = false
            return
        }

        logger.info("🌤️ Fetching weather for city: \(city)")
        print("🌤️ [DEBUG] Fetching weather for city: \(city)")

        // First, geocode the city name to get coordinates
        geocoder.geocodeAddressString(city) { [weak self] placemarks, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.logger.error("❌ Geocoding error: \(error.localizedDescription)")
                    print("❌ [DEBUG] Geocoding error: \(error.localizedDescription)")
                    self.errorMessage = "City not found"
                    self.isLoading = false
                }
                return
            }

            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                DispatchQueue.main.async {
                    self.logger.error("❌ No location found for city: \(city)")
                    print("❌ [DEBUG] No location found for city: \(city)")
                    self.errorMessage = "City not found"
                    self.isLoading = false
                }
                return
            }

            print("📍 [DEBUG] Geocoded \(city) to: lat=\(location.coordinate.latitude), lon=\(location.coordinate.longitude)")

            // Get the city name from the placemark for consistent display
            let cityName = placemark.locality ?? placemark.name ?? city
            let timezoneOffset = placemark.timeZone?.secondsFromGMT() ?? 0

            // Fetch weather using coordinates
            self.fetchWeatherKitData(location: location, cityName: cityName, timezoneOffset: timezoneOffset)
        }
    }

    // MARK: - Fetch Weather by Coordinates
    func fetchWeatherByCoordinates(lat: Double, lon: Double) {
        isLoading = true
        errorMessage = nil

        logger.info("📍 Fetching weather for coordinates: lat=\(lat), lon=\(lon)")

        let location = CLLocation(latitude: lat, longitude: lon)

        // Reverse geocode to get city name
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }

            let cityName: String
            let timezoneOffset: Int

            if let placemark = placemarks?.first {
                cityName = placemark.locality ?? placemark.name ?? "Unknown Location"
                timezoneOffset = placemark.timeZone?.secondsFromGMT() ?? 0
            } else {
                cityName = "Current Location"
                timezoneOffset = TimeZone.current.secondsFromGMT()
            }

            self.fetchWeatherKitData(location: location, cityName: cityName, timezoneOffset: timezoneOffset)
        }
    }

    // MARK: - WeatherKit Data Fetch
    private func fetchWeatherKitData(location: CLLocation, cityName: String, timezoneOffset: Int) {
        Task {
            do {
                print("🌤️ [DEBUG] Fetching WeatherKit data for: \(cityName)")

                let weather = try await weatherService.weather(for: location)

                print("✅ [DEBUG] Successfully received WeatherKit data")
                print("🌡️ [DEBUG] Temperature: \(weather.currentWeather.temperature.value)°\(weather.currentWeather.temperature.unit.symbol)")
                print("☁️ [DEBUG] Condition: \(weather.currentWeather.condition.description)")

                await MainActor.run {
                    // Get today's forecast for accurate high/low and sun times
                    let todayForecast = weather.dailyForecast.forecast.first

                    // Create WeatherDisplay from WeatherKit data
                    let weatherDisplay = WeatherDisplay(
                        from: weather.currentWeather,
                        dayWeather: todayForecast,
                        cityName: cityName,
                        timezoneOffset: timezoneOffset
                    )

                    self.weather = weatherDisplay

                    // Process hourly forecasts (next 24 hours)
                    let next24Hours = weather.hourlyForecast.forecast.prefix(24)
                    self.hourlyForecasts = next24Hours.map { hourWeather in
                        HourlyForecast(from: hourWeather, timezoneOffset: timezoneOffset)
                    }

                    // Process daily forecasts (next 5 days)
                    let next5Days = weather.dailyForecast.forecast.prefix(5)
                    self.dailyForecasts = next5Days.enumerated().map { index, dayWeather in
                        DailyForecast(from: dayWeather, timezoneOffset: timezoneOffset, isToday: index == 0)
                    }

                    self.isLoading = false
                    self.errorMessage = nil

                    print("🎉 [DEBUG] Weather data successfully processed and displayed")
                    print(String(repeating: "=", count: 50))
                    print("🏁 [DEBUG] WEATHER REQUEST COMPLETED")
                    print(String(repeating: "=", count: 50) + "\n")
                }
            } catch {
                await MainActor.run {
                    self.logger.error("❌ WeatherKit error: \(error.localizedDescription)")
                    print("❌ [DEBUG] WeatherKit error: \(error.localizedDescription)")
                    print("❌ [DEBUG] Error details: \(error)")

                    let nsError = error as NSError
                    print("❌ [DEBUG] Error domain: \(nsError.domain)")
                    print("❌ [DEBUG] Error code: \(nsError.code)")

                    // Check for specific error types
                    if nsError.domain == "WeatherDaemon.WDSJWTAuthenticatorServiceListener.Errors" {
                        self.errorMessage = "WeatherKit not authorized. Please ensure WeatherKit is enabled in Apple Developer Portal for this app."
                    } else if let weatherError = error as? WeatherKit.WeatherError {
                        switch weatherError {
                        default:
                            self.errorMessage = "Unable to fetch weather data. Please try again."
                        }
                    } else {
                        self.errorMessage = "Weather service error: \(nsError.localizedDescription)"
                    }

                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Location Services
    func requestLocation() {
        locationManager.requestLocation()
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentCity: String = "Getting location..."

    // Add completion handler for location updates
    var onLocationReceived: ((CLLocation) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 1000

        // Check current authorization status
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestLocation() {
        print("📍 [DEBUG] Requesting location...")
        currentCity = "Getting location..."

        let currentStatus = locationManager.authorizationStatus
        print("📍 [DEBUG] Current authorization status: \(currentStatus.rawValue)")

        switch currentStatus {
        case .notDetermined:
            print("📍 [DEBUG] Permission not determined, requesting permission...")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("📍 [DEBUG] Permission denied/restricted, cannot request location")
            DispatchQueue.main.async {
                self.currentCity = "Location access denied"
            }
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 [DEBUG] Permission granted, requesting location...")
            locationManager.requestLocation()
        @unknown default:
            print("📍 [DEBUG] Unknown authorization status, requesting permission...")
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📍 [DEBUG] Location received: \(location.coordinate)")
        print("📍 [DEBUG] Location accuracy: \(location.horizontalAccuracy) meters")

        let timeSinceUpdate = Date().timeIntervalSince(location.timestamp)
        if timeSinceUpdate < 1800 && location.horizontalAccuracy <= 5000 {
            self.location = location
            print("📍 [DEBUG] Location accepted and stored")

            // Reverse geocode to get city name
            reverseGeocodeLocation(location)

            // Notify the weather service that location was received
            onLocationReceived?(location)
        } else {
            print("📍 [DEBUG] Location rejected - too old or inaccurate")
            if currentCity == "Getting location..." {
                DispatchQueue.main.async {
                    self.currentCity = "Unable to determine precise location"
                }
            }
        }
    }

    private func reverseGeocodeLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        print("📍 [DEBUG] Starting reverse geocoding for coordinates: \(location.coordinate)")

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("📍 [DEBUG] Reverse geocoding error: \(error.localizedDescription)")
                    self?.currentCity = "Location error"
                    return
                }

                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? placemark.subLocality ?? placemark.administrativeArea ?? "Unknown City"
                    self?.currentCity = city
                    print("📍 [DEBUG] Final city name set to: \(city)")
                } else {
                    self?.currentCity = "Unknown location"
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 [DEBUG] Location error: \(error.localizedDescription)")

        DispatchQueue.main.async {
            self.currentCity = "Location error"
        }

        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                DispatchQueue.main.async {
                    self.currentCity = "Access denied"
                }
            case .locationUnknown:
                DispatchQueue.main.async {
                    self.currentCity = "Location unavailable"
                }
            case .network:
                DispatchQueue.main.async {
                    self.currentCity = "Network error"
                }
            default:
                DispatchQueue.main.async {
                    self.currentCity = "Location error"
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 [DEBUG] Authorization status changed to: \(status.rawValue)")
        authorizationStatus = status

        DispatchQueue.main.async {
            self.authorizationStatus = status
        }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 [DEBUG] Permission granted, requesting location...")
            currentCity = "Getting location..."
            locationManager.requestLocation()
        case .denied, .restricted:
            print("📍 [DEBUG] Permission denied/restricted")
            currentCity = "Location access denied"
        case .notDetermined:
            print("📍 [DEBUG] Permission not determined")
            currentCity = "Location permission needed"
        @unknown default:
            print("📍 [DEBUG] Unknown authorization status")
            currentCity = "Location status unknown"
        }
    }
}
