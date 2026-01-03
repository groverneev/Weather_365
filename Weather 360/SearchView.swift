import SwiftUI
import UIKit

struct SearchView: View {
    @StateObject private var weatherService = WeatherService()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var cityInput = ""
    @State private var showingLocationAlert = false
    @State private var locationAlertMessage = ""
    @State private var isCelsius = false // Temperature unit toggle - default to Fahrenheit
    @State private var showWeatherSheet = false // Explicit control for showing weather

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // Use device idiom as fallback for iPad detection (handles Split View edge cases)
    private var isRegularLayout: Bool {
        // Check both size class AND device idiom for more reliable iPad detection
        if UIDevice.current.userInterfaceIdiom == .pad {
            // On iPad, use regular layout unless in very compact split view
            return horizontalSizeClass != .compact || UIScreen.main.bounds.width > 500
        }
        return horizontalSizeClass == .regular
    }

    var body: some View {
        Group {
            if isRegularLayout {
                if #available(iOS 16.0, *) {
                    NavigationSplitView(columnVisibility: .constant(.all)) {
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
                            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
                    } detail: {
                        if weatherService.isLoading {
                            loadingView
                        } else if let errorMessage = weatherService.errorMessage {
                            errorView(message: errorMessage)
                        } else if let weather = weatherService.weather {
                            WeatherView(weather: weather, isCelsius: isCelsius)
                                .environmentObject(themeManager)
                                .environmentObject(weatherService)
                        } else {
                            placeholderView
                        }
                    }
                    .navigationSplitViewStyle(.balanced)
                } else {
                    // iOS 15 iPad fallback - use NavigationView with proper styling
                    iPadLegacyLayout
                }
            } else {
                // iPhone layout
                iPhoneLayout
            }
        }
        .background(themeManager.isDarkMode ? Color(.systemGray6) : Color(.systemBackground))
    }

    // MARK: - Layout Views

    private var iPadLegacyLayout: some View {
        NavigationView {
            searchContent
                .navigationBarHidden(true)

            // Detail view for iPad NavigationView
            if weatherService.isLoading {
                loadingView
            } else if let errorMessage = weatherService.errorMessage {
                errorView(message: errorMessage)
            } else if let weather = weatherService.weather {
                WeatherView(weather: weather, isCelsius: isCelsius)
                    .environmentObject(themeManager)
                    .environmentObject(weatherService)
            } else {
                placeholderView
            }
        }
        .navigationViewStyle(.columns)
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

    private var iPhoneLayout: some View {
        NavigationView {
            ZStack {
                searchContent
                    .navigationBarHidden(true)

                // Loading overlay for iPhone
                if weatherService.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    loadingView
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(themeManager.isDarkMode ? Color(.systemGray5) : Color.white)
                                .shadow(radius: 10)
                        )
                        .padding(40)
                }
            }
            .sheet(isPresented: $showWeatherSheet) {
                if let weather = weatherService.weather {
                    WeatherView(weather: weather, isCelsius: isCelsius)
                        .environmentObject(themeManager)
                        .environmentObject(weatherService)
                }
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
            .alert("Error", isPresented: .constant(weatherService.errorMessage != nil && !weatherService.isLoading)) {
                Button("OK") {
                    weatherService.errorMessage = nil
                }
            } message: {
                Text(weatherService.errorMessage ?? "An error occurred")
            }
        }
        .navigationViewStyle(.stack)
        .onChange(of: weatherService.weather) { newWeather in
            // Show sheet when weather data is loaded on iPhone
            if newWeather != nil && !weatherService.isLoading {
                showWeatherSheet = true
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            Text("Loading weather...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var placeholderView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            Text("Search for a city")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text("Enter a city name to view the forecast")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text("Error")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                if !cityInput.isEmpty {
                    weatherService.fetchWeather(for: cityInput)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var searchContent: some View {
        GeometryReader { geometry in
            let isCompactHeight = geometry.size.height < 600
            let horizontalPadding: CGFloat = min(max(geometry.size.width * 0.05, 16), 40)

            ScrollView {
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
                                .lineLimit(1)

                            // Refresh location button
                            Button(action: {
                                weatherService.locationManager.requestLocation()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            .frame(minWidth: 44, minHeight: 44) // Minimum tap target
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
                        .frame(minWidth: 44, minHeight: 44) // Minimum tap target
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 10)
                    .background(themeManager.isDarkMode ? Color(.systemGray6) : Color(.systemBackground))

                    // Main content
                    VStack(spacing: isCompactHeight ? 20 : 30) {
                        Spacer(minLength: isCompactHeight ? 20 : 40)

                        // App title
                        VStack(spacing: 10) {
                            Text("Weather 360")
                                .font(isCompactHeight ? .title : .largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("Get accurate weather information for any city")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, horizontalPadding)
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
                                    .frame(width: 50, height: 44) // Minimum tap height
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
                                    .frame(width: 50, height: 44) // Minimum tap height
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
                                .font(.body)
                                .frame(minHeight: 44) // Minimum tap height
                                .padding(.horizontal, horizontalPadding)
                                .submitLabel(.search)
                                .onSubmit {
                                    if !cityInput.isEmpty {
                                        hideKeyboard()
                                        weatherService.fetchWeather(for: cityInput)
                                    }
                                }

                            Button(action: {
                                hideKeyboard()
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
                                .frame(minHeight: 50) // Minimum tap height
                                .background(cityInput.isEmpty ? Color.gray : Color.blue)
                                .cornerRadius(15)
                            }
                            .disabled(cityInput.isEmpty || weatherService.isLoading)
                            .padding(.horizontal, horizontalPadding)
                        }

                        // Current Location Button
                        Button(action: {
                            hideKeyboard()
                            handleLocationRequest()
                        }) {
                            HStack {
                                Image(systemName: locationButtonIcon)
                                Text(locationButtonText)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 50) // Minimum tap height
                            .background(weatherService.isLoading ? Color.gray : locationButtonColor)
                            .cornerRadius(15)
                        }
                        .disabled(weatherService.isLoading)
                        .padding(.horizontal, horizontalPadding)

                        Spacer(minLength: isCompactHeight ? 20 : 40)
                    }
                    .padding(.top, isCompactHeight ? 10 : 20)
                    .frame(minHeight: geometry.size.height - 60) // Ensure content fills available space
                }
            }
        }
    }

    // Helper to dismiss keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
