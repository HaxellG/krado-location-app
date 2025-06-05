import SwiftUI

@main
struct locationApp: App {

    init() {
        // Configura servicios (S3/DynamoDB) vía Cognito, si los usas
        AWSBootstrap.configure()

        // Conexión a IoT mediante WebSocket SigV4
        IoTManager.shared.connect { ok in
            print(ok ? "✅ IoT conectado" : "❌ IoT no conectado")
        }
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
