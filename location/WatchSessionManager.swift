import Foundation
import WatchConnectivity
import Combine

final class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    private let session = WCSession.default

    @Published var isWatchConnected: Bool = false
    @Published var customData: [String:Any]? = nil

    private override init() {
        super.init()
        session.delegate = self
        session.activate()
    }

    /// Sirve para que otros sepan si pueden enviar mensajes
    func sendPing() {
        isWatchConnected = session.isReachable
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
        var trash = 0
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        var trash = 0
    }
    
    func session(_ session: WCSession, activationDidCompleteWith
       activationState: WCSessionActivationState, error: Error?) {
        isWatchConnected = session.isReachable
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        isWatchConnected = session.isReachable
        if !isWatchConnected {
          customData = nil
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Mensaje del Watch con pasos/BPM
        customData = message
    }
}
