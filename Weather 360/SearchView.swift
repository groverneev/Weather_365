import SwiftUI
import UIKit

struct SearchView: View {
    @StateObject private var weatherService = WeatherService()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var cityInput = ""
    @State private var showingLocationAlert = false
    @State private var locationAlertMessage = ""
    @State private var isCelsius = false // Temperature unit toggle - default to Fahrenheit
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                if #available(iOS 16.0, *) {
                    NavigationSplitView {
                        searchContent
                            .alert("Location Access Required", isPresented: $showingLocationAlert) {
                                Button("Cancel", role: .cancel) { }
                                Button("Open Settings") {
                                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(settingsUrl)
                                    }
                                }
                            } message: {
                                Text("Location access is required to get weather for your current location. Please enable location access in Settings.\n\n1. Tap 'Open Settings'\n2. Tap 'Privacy & Security'\n3. Tap 'Location Services'\n4. Find 'Weather 360' and enable it")
                            }
                    } detail: {
                        if let weather = weatherService.weather {
                            WeatherView(weather: weather, isCelsius: isCelsius)
                                .environmentObject(themeManager)
                                .environmentObject(weatherService)
                        } else {
                            VStack(spacing: 20) {
                                Image(systemName: "cloud.sun.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("Search for a city")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Text("Enter a city name in the sidebar to view the forecast")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                    }
                } else {
                    standardLayout
                }
            } else {
                standardLayout
            }
        }
        .background(themeManager.isDarkMode ? Color(.systemGray6) : Color(.systemBackground))
    }
    
    var standardLayout: some View {
        NavigationView {
            searchContent
                .navigationBarHidden(true)
                .sheet(item: $weatherService.weather) { weather in
                    WeatherView(weather: weather, isCelsius: isCelsius)
                        .environmentObject(themeManager)
                        .environmentObject(weatherService)
                }
                .alert("Location Access Required", isPresented: $showingLocationAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Open Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                } message: {
                    Text("Location access is required to get weather for your current location. Please enable location access in Settings.\n\n1. Tap 'Open Settings'\n2. Tap 'Privacy & Security'\n3. Tap 'Location Services'\n4. Find 'Weather 360' and enable it")
                }
        }
    }
    
    var searchContent: some View {
        VStack(spacing: 0) {
            // Top bar with current location and theme toggle
            HStack {
                // Current location display
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text(weatherService.locationManager.currentCity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Refresh location button
                    Button(action: {
                        weatherService.locationManager.requestLocation()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Theme toggle
                Button(action: {
                    themeManager.toggleTheme()
                }) {
                    Image(systemName: themeManager.isDarkMode ? "sun.max.fill" : "moon.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.isDarkMode ? .yellow : .purple)
                        .padding(8)
                        .background(themeManager.isDarkMode ? Color.yellow.opacity(0.2) : Color.purple.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(themeManager.isDarkMode ? Color(.systemGray6) : Color(.systemBackground))
            
            // Main content
            VStack(spacing: 30) {
                Spacer()
                
                // App title
                VStack(spacing: 10) {
                    Text("Weather 360")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Get accurate weather information for any city")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Temperature unit toggle
                HStack(spacing: 0) {
                    Button(action: {
                        isCelsius = false
                    }) {
                        Text("°F")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(!isCelsius ? .white : .blue)
                            .frame(width: 50, height: 40)
                            .background(!isCelsius ? Color.blue : Color.blue.opacity(0.1))
                            .roundedCorner(8, corners: [.topLeft, .bottomLeft])
                    }
                    
                    Button(action: {
                        isCelsius = true
                    }) {
                        Text("°C")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(isCelsius ? .white : .blue)
                            .frame(width: 50, height: 40)
                            .background(isCelsius ? Color.blue : Color.blue.opacity(0.1))
                            .roundedCorner(8, corners: [.topRight, .bottomRight])
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                
                // Search input
                VStack(spacing: 15) {
                    TextField("Enter city name", text: $cityInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .padding(.horizontal, 20)
                    
                    Button(action: {
                        if !cityInput.isEmpty {
                            weatherService.fetchWeather(for: cityInput)
                        }
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search Weather")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                    }
                    .disabled(cityInput.isEmpty)
                    .padding(.horizontal, 20)
                }
                
                // Current Location Button
                Button(action: {
                    handleLocationRequest()
                }) {
                    HStack {
                        Image(systemName: locationButtonIcon)
                        Text(locationButtonText)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(locationButtonColor)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 20)
                
                // Location status info removed - was showing "location access granted" text
                
                Spacer()
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Computed Properties
    
    private var locationButtonIcon: String {
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            return "location.slash"
        case .notDetermined:
            return "location"
        case .authorizedWhenInUse, .authorizedAlways:
            return "location.fill"
        @unknown default:
            return "location"
        }
    }
    
    private var locationButtonText: String {
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            return "Location Access Denied"
        case .notDetermined:
            return "Use Current Location"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Use Current Location"
        @unknown default:
            return "Use Current Location"
        }
    }
    
    private var locationButtonColor: Color {
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .blue
        case .authorizedWhenInUse, .authorizedAlways:
            return .blue
        @unknown default:
            return .blue
        }
    }
    
    private var locationStatusIcon: String {
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            return "exclamationmark.triangle.fill"
        case .notDetermined:
            return "questionmark.circle"
        case .authorizedWhenInUse, .authorizedAlways:
            return "checkmark.circle.fill"
        @unknown default:
            return "questionmark.circle"
        }
    }
    
    private var locationStatusColor: Color {
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        @unknown default:
            return .orange
        }
    }
    
    private var locationStatusText: String {
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            return "Location access denied"
        case .notDetermined:
            return "Location permission not determined"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Location access granted"
        @unknown default:
            return "Location permission unknown"
        }
    }
    
    private var locationStatusView: some View {
        HStack(spacing: 8) {
            Image(systemName: locationStatusIcon)
            .foregroundColor(locationStatusColor)
            .font(.caption)
            Text(locationStatusText)
            .font(.caption)
            .foregroundColor(locationStatusColor)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Methods
    
    private func handleLocationRequest() {
        print("📍 [DEBUG] SearchView: Handling location request...")
        print("📍 [DEBUG] Current authorization status: \(weatherService.locationManager.authorizationStatus.rawValue)")
        
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            print("📍 [DEBUG] Location access denied, showing settings alert")
            locationAlertMessage = "Location access is required to get weather for your current location. Please enable location access in Settings."
            showingLocationAlert = true
        case .notDetermined:
            print("📍 [DEBUG] Permission not determined, requesting permission")
            weatherService.locationManager.requestLocation()
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 [DEBUG] Permission granted, requesting location")
            weatherService.locationManager.requestLocation()
        @unknown default:
            print("📍 [DEBUG] Unknown status, requesting permission")
            weatherService.locationManager.requestLocation()
        }
    }
}

// MARK: - Custom Corner Radius Extension
extension View {
    func roundedCorner(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    SearchView()
        .environmentObject(ThemeManager())
}
