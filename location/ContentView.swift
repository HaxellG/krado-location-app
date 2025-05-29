import SwiftUI
import PhotosUI


struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var watchSession = WatchSessionManager.shared
    
    @State private var showCamera   = false
    @State private var lastPhoto:   UIImage? = nil

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
                // Título principal y estado del Watch
                HStack(spacing: 12) {
                    Image(systemName: watchSession.isWatchConnected ? "applewatch.watchface" : "applewatch.slash")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(watchSession.isWatchConnected ? .green : .red)
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
                                ))
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                    
                    VStack {
                        Spacer()
                        
                        // Botón elegante morado
                        Button {
                            showCamera = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20, weight: .bold))
                                Text("Tomar foto")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(colors: [
                                    Color(red: 0.5, green: 0.0, blue: 1.0),
                                    Color(red: 0.3, green: 0.0, blue: 0.6)
                                ], startPoint: .top, endPoint: .bottom)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(30)
                            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 4)
                        }
                        .sheet(isPresented: $showCamera) {
                            ImagePicker { img in
                                self.lastPhoto = img
                                if let loc = locationManager.userLocation {
                                    S3Uploader.shared.upload(
                                        image: img,
                                        deviceId: "3014344057",
                                        coord: loc.coordinate) { result in
                                            switch result {
                                            case .success: print("✅ Foto subida y registrada")
                                            case .failure(let err): print("❌", err)
                                            }
                                    }
                                }
                            }
                        }
                        
                        if let thumb = lastPhoto {
                            Image(uiImage: thumb)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.top, 8)
                        }
                    }
                    .padding(.bottom, 30)
                }

                    // Datos del Watch si está conectado
                    if watchSession.isWatchConnected, let custom = watchSession.customData {
                        Divider().background(Color.white.opacity(0.5))
                        InfoRow(icon: "heart.fill",
                                label: "BPM",
                                value: String(format: "%.0f", custom["heartRate"] as? Double ?? 0))
                        InfoRow(icon: "figure.walk",
                                label: "Pasos",
                                value: "\(custom["steps"] as? Int ?? 0)")
                    } else {
                        Text("📴 Watch desconectado")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
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

// MARK: - Fila estilizada con icono, etiqueta y valor
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
