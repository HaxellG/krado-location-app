import Foundation
import AWSCore
import AWSIoT
import CoreLocation

/// Gestor para conectarse a AWS IoT con WebSocket
final class IoTManager {

    static let shared = IoTManager()

    private let endpointHost = " "
    private let region: AWSRegionType = .USEast1

    private let accessKey    = " "
    private let secretKey    = " "
    private let sessionToken = " " 

    private var dataManager: AWSIoTDataManager?

    private init() {
        // 1. Proveedor de credenciales estáticas
        let creds = AWSStaticCredentialsProvider(
            accessKey: accessKey,
            secretKey: secretKey
        )

        // 2. Endpoint WebSocket
        let endpoint = AWSEndpoint(
            urlString: "wss://\(endpointHost)/mqtt"
        )

        let cfg = AWSServiceConfiguration(
            region: region,
            endpoint: endpoint,
            credentialsProvider: creds
        )!
        AWSServiceManager.default().defaultServiceConfiguration = cfg

        // 3. Registrar IoTDataManager
        AWSIoTDataManager.register(with: cfg, forKey: "WebSocketDM")
        dataManager = AWSIoTDataManager(forKey: "WebSocketDM")
    }

    // MARK: – Conexión
    func connect(completion: @escaping (Bool) -> Void) {
        guard let dm = dataManager else { completion(false); return }

        let clientId = "ios-" + UUID().uuidString
        dm.connectUsingWebSocket(
            withClientId: clientId,
            cleanSession: true
        ) { status in
            print("[IoT] estado \(status) (\(status.rawValue))")
            completion(status == .connected)
        }
    }

    // MARK: – Publicación de ubicación
    func publishLocation(lat: Double, lon: Double, alt: Double) {
        guard let dm = dataManager else { return }
        let topic = "devices/3014344057/gps"

        var payload: [String: Any] = [
            "latitude":  lat,
            "longitude": lon,
            "altitude":  alt,
            "timestamp": Date().timeIntervalSince1970
        ]

        // Datos del watch, si existen
        if let custom = WatchSessionManager.shared.customData,
           WatchSessionManager.shared.isWatchConnected {
            payload["custom"] = custom
        } else {
            payload["custom"] = NSNull()
        }

        if
            let json = try? JSONSerialization.data(withJSONObject: payload),
            let str  = String(data: json, encoding: .utf8)
        {
            dm.publishString(str,
                             onTopic: topic,
                             qoS: .messageDeliveryAttemptedAtLeastOnce)
            print("Publicado en \(topic): \(str)")
        }
    }
}
