import AWSCore
import AWSIoT

class IoTManager {
    static let shared = IoTManager()
    
    private var dataManager: AWSIoTDataManager?
    
    // Endpoint de AWS IoT
    private let iotEndPoint = "a3o7s9e6i7d5y3-ats.iot.us-east-1.amazonaws.com"
    private let region: AWSRegionType = .USEast1
    
    private init() {
        // 1. Crear AWSEndpoint
        let iotEndpoint = AWSEndpoint(urlString: "https://\(iotEndPoint)")
        
        // 2. Configurar el AWSServiceConfiguration
        let serviceConfig = AWSServiceConfiguration(
            region: region,
            endpoint: iotEndpoint,
            credentialsProvider: nil
        )
        
        // 3. Registrar IoTDataManager
        AWSIoTDataManager.register(with: serviceConfig!, forKey: "MyIoTDataManager")
        
        // 4. Obtener la instancia
        self.dataManager = AWSIoTDataManager(forKey: "MyIoTDataManager")
    }
    
    func connect(completion: @escaping (Bool) -> Void) {
        guard let dataManager = dataManager else {
            completion(false)
            return
        }
        
        let certId = "kradoCertificateId"  // ID de importCertificate
        let clientId = "cliente-\(UUID().uuidString)"
        
        dataManager.connect(
            withClientId: clientId,
            cleanSession: true,
            certificateId: certId
        ) { status in
            switch status {
            case .connected:
                print("Conectado a AWS IoT Core (MQTT/TLS).")
                completion(true)
            case .connectionError, .connectionRefused, .disconnected:
                print("Error de conexión: \(status.rawValue)")
                completion(false)
            default:
                print("Estado: \(status.rawValue)")
            }
        }
    }
    
    func publishLocation(lat: Double, lon: Double) {
        guard let dataManager = dataManager else { return }
        let topic = "location/gps" // Tópico
        
        let message = [
            "latitude": lat,
            "longitude": lon,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            dataManager.publishString(
                jsonString,
                onTopic: topic,
                qoS: .messageDeliveryAttemptedAtLeastOnce
            )
            print("Publicado en \(topic): \(jsonString)")
        }
    }
}
