import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    
    override init() {
        super.init()
        
        // 1. Configurar CoreLocation
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true  // Para ejecución en segundo plano
        locationManager.startUpdatingLocation()
        
        // 2. Importar el certificado .p12
        do {
            try CertificateHelper.importCertificate()  // El .p12 se importa en la keychain
        } catch {
            print("Error al importar .p12: \(error.localizedDescription)")
        }
        
        // Iniciar la conexión a IoT Core
        IoTManager.shared.connect { success in
            if success {
                print("Conectado a AWS IoT via MQTT/TLS. Listo para publicar ubicación.")
            } else {
                print("No se pudo conectar a AWS IoT.")
            }
        }
    }
    
    // Cada vez que se obtiene una nueva coordenada
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Actualizar la interfaz
        DispatchQueue.main.async {
            self.userLocation = location
        }
        
        // Publicar en AWS IoT
        IoTManager.shared.publishLocation(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude
        )
    }
    
    // Manejo de errores de GPS
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener ubicación: \(error.localizedDescription)")
    }
}
