import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        ZStack {
            // Fondo con degradado púrpura oscuro
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.10, green: 0.00, blue: 0.30),
                    Color(red: 0.30, green: 0.00, blue: 0.50)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Título principal fuera de la tarjeta
                HStack(spacing: 12) {
                    Image(systemName: "satellite.fill")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(Color.purple.opacity(0.9))
                    Text("Krado App")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)
                
                // Tarjeta de información
                VStack(spacing: 20) {
                    if let loc = locationManager.userLocation {
                        InfoRow(icon: "location.north.line.fill",
                                label: "Latitud",
                                value: String(format: "%.6f", loc.coordinate.latitude))
                        InfoRow(icon: "globe",
                                label: "Longitud",
                                value: String(format: "%.6f", loc.coordinate.longitude))
                        InfoRow(icon: "location.fill",
                                label: "Altitud",
                                value: String(format: "%.2f m", loc.altitude))
                        InfoRow(icon: "clock.fill",
                                label: "Actualizado",
                                value: DateFormatter.localizedString(
                                    from: loc.timestamp,
                                    dateStyle: .none,
                                    timeStyle: .medium
                                )
                        )
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.8),
                                    Color(red: 0.8, green: 0.00, blue: 0.9)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.black.opacity(0.6), radius: 12, x: 0, y: 6)
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

/// Fila estilizada con icono, etiqueta y valor
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color.purple.opacity(0.9))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
