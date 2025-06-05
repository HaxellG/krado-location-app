import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var watchSession   = WatchSessionManager.shared

    // MARK: — Estados para la cámara y el modal
    @State private var showCamera             = false
    @State private var selectedImage: UIImage? = nil
    @State private var showPreview            = false

    // Campos de texto para título, descripción y tag
    @State private var eventTitle: String       = ""
    @State private var eventDescription: String = ""
    @State private var eventTag: String         = "Novedad" // Valor por defecto

    // MARK: — Último evento publicado
    @State private var lastPhoto: UIImage? = nil
    @State private var lastTitle: String   = ""
    @State private var lastTag: String     = ""      // opcional

    // Opciones de tag
    private let tagOptions = ["Novedad", "Precaución", "Urgente", "Positivo"]

    var body: some View {
        ZStack {
            // — Fondo degradado púrpura
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
                // Título con icono de satélite
                HStack(spacing: 12) {
                    Image(systemName: "satellite.fill")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(Color.purple.opacity(0.9))
                    Text("Krado App")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)

                // Tarjeta de datos de ubicación + datos del reloj
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

                    // — Datos del Apple Watch desde customData
                    InfoRow(
                        icon: "heart.fill",
                        label: "BPM",
                        value: {
                            if let hr = watchSession.customData?["heartRate"] as? Double {
                                return "\(Int(hr))"
                            } else {
                                return "N/A"
                            }
                        }()
                    )
                    InfoRow(
                        icon: "figure.walk",
                        label: "Pasos",
                        value: {
                            if let steps = watchSession.customData?["stepCount"] as? Int {
                                return "\(steps)"
                            } else {
                                return "N/A"
                            }
                        }()
                    )

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

                // -------------- Previsualización del último evento --------------
                if let lastImg = lastPhoto {
                    VStack(spacing: 8) {
                        Image(uiImage: lastImg)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)

                        Text(lastTitle)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)

                        // Mostrar la etiqueta del último evento, si existe
                        if !lastTag.isEmpty {
                            Text(lastTag)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                    }
                    .padding(.top, 16)
                }

                Spacer()

                // Botón para abrir la cámara
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
                .padding(.bottom, 30)
            }

            // -------------- Sheet para Cámara --------------
            .sheet(isPresented: $showCamera) {
                ImagePicker { img in
                    selectedImage = img
                    showCamera    = false
                    showPreview   = true
                }
            }

            // -------------- Sheet para Preview + Inputs + Picker --------------
            .sheet(isPresented: $showPreview) {
                if let img = selectedImage,
                   let loc = locationManager.userLocation {
                    PhotoPreviewModal(
                        image: img,
                        userLocation: loc,
                        isPresented: $showPreview,
                        lastPhoto: $lastPhoto,
                        lastTitle: $lastTitle,
                        lastTag: $lastTag,
                        title: $eventTitle,
                        description: $eventDescription,
                        tag: $eventTag,
                        tagOptions: tagOptions
                    )
                }
            }
        }
    }
}

/// Vista que muestra la foto + inputs + Picker + botón “Publicar” + spinner
struct PhotoPreviewModal: View {
    let image: UIImage
    let userLocation: CLLocation

    // Vinculaciones con la vista principal
    @Binding var isPresented: Bool
    @Binding var lastPhoto: UIImage?
    @Binding var lastTitle: String
    @Binding var lastTag: String

    // Inputs que el usuario escribe
    @Binding var title: String
    @Binding var description: String
    @Binding var tag: String

    let tagOptions: [String]

    // Estado para el spinner
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Previsualización de la imagen con marco redondeado
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
                    .padding(.top, 20)

                // Input: Título del evento
                VStack(alignment: .leading, spacing: 4) {
                    Text("Título")
                        .font(.headline)
                    TextField("Escribe un título...", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                // Input: Descripción del evento
                VStack(alignment: .leading, spacing: 4) {
                    Text("Descripción")
                        .font(.headline)
                    TextField("Escribe una descripción...", text: $description)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                // Picker: Seleccionar tag
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tag")
                        .font(.headline)
                    Picker("Selecciona un tag", selection: $tag) {
                        ForEach(tagOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal)

                Spacer()

                // Botón “Publicar” o Spinner si está cargando
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(
                            tint: Color.purple.opacity(0.8)))
                        .scaleEffect(1.5)
                        .padding()
                } else {
                    Button {
                        // Iniciar spinner
                        isLoading = true

                        // Llamar a S3Uploader con todos los datos, incluido tag
                        S3Uploader.shared.upload(
                            image: image,
                            deviceId: "3014344057",
                            coord: userLocation.coordinate,
                            altitude: userLocation.altitude,
                            title: title,
                            description: description,
                            tag: tag
                        ) { result in
                            DispatchQueue.main.async {
                                isLoading = false

                                switch result {
                                case .success:
                                    // Guardar último evento: foto, título y tag
                                    lastPhoto = image
                                    lastTitle = title
                                    lastTag = tag
                                case .failure(let err):
                                    print("❌ Error al publicar:", err)
                                }
                                // Limpiar campos y cerrar modal
                                title       = ""
                                description = ""
                                tag         = tagOptions.first ?? ""
                                isPresented = false
                            }
                        }
                    } label: {
                        Text("Publicar")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [
                                    Color(red: 0.6, green: 0.0, blue: 1.0),
                                    Color(red: 0.4, green: 0.0, blue: 0.7)
                                ], startPoint: .top, endPoint: .bottom)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .opacity((title.isEmpty || description.isEmpty) ? 0.5 : 1.0)
                    }
                    .disabled(title.isEmpty || description.isEmpty)
                }

                Spacer()
            }
            .navigationTitle("Publicar Imagen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Botón “Cancelar” para cerrar modal sin publicar
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        title       = ""
                        description = ""
                        tag         = tagOptions.first ?? ""
                        isPresented = false
                    }
                }
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
