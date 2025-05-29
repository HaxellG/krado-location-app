import SwiftUI

struct ContentView: View {
    @StateObject private var health = HealthManager.shared

    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 0.15, green: 0.00, blue: 0.35),
                Color(red: 0.35, green: 0.00, blue: 0.55)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Krado Watch")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                MetricRow(icon: "heart.fill",
                          color: .red,
                          label: "BPM",
                          value: String(format: "%.0f", health.heartRate))

                MetricRow(icon: "figure.walk",
                          color: .green,
                          label: "Pasos",
                          value: "\(health.stepCount)")
            }
            .padding()
        }
    }
}

struct MetricRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}
