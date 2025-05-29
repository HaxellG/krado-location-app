import Foundation
import WatchConnectivity

final class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    /// Envía el JSON al iPhone si la sesión está reachable
    func send(metrics: [String: Any]) {
        guard let session = session,
              session.isReachable else {
            // El iPhone no está reachable en este momento
            return
        }
        session.sendMessage(metrics, replyHandler: nil) { error in
            print("❌ Error enviando datos al iPhone:", error)
        }
    }

    // MARK: - WCSessionDelegate stubs

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        // No-op
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        // Podrías usar esto para actualizar alguna UI
    }
}
