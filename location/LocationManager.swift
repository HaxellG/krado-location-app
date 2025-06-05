import Foundation
import CoreLocation
import Combine

/// Provee la ubicación del usuario (lat, lon, altitud)
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var userLocation: CLLocation?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    // Delegate
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async { self.userLocation = loc }

        // Enviar cada nueva posición a AWS IoT
        IoTManager.shared.publishLocation(
            lat: loc.coordinate.latitude,
            lon: loc.coordinate.longitude,
            alt: loc.altitude
        )
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
}
