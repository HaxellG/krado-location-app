import SwiftUI

@main
struct locationApp: App {
    init() {
        do {
            try CertificateHelper.importCertificate()
        } catch {
            print("Error importando .p12: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
