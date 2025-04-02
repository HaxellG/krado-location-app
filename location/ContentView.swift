import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack {
            if let location = locationManager.userLocation {
                Text("Latitud: \(location.coordinate.latitude)")
                Text("Longitud: \(location.coordinate.longitude)")
            } else {
                Text("Obteniendo ubicación...")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
