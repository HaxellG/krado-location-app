import HealthKit
import Combine

final class HealthManager: NSObject,
                           ObservableObject,
                           HKWorkoutSessionDelegate,
                           HKLiveWorkoutBuilderDelegate {

    // MARK: - Publicados
    @Published var heartRate: Double = 0
    @Published var stepCount: Int    = 0          // pasos “desde 0” para la UI

    // MARK: - Privados
    static let shared = HealthManager()
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    /// Línea base de pasos cuando se abre la app. Nil hasta la 1.ª lectura.
    private var baselineSteps: Int?

    private override init() { super.init() }

    // MARK: - Autorización
    func requestAuthorization() {
        let readTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.workoutType()
        ]
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { ok, err in
            if ok { DispatchQueue.main.async { self.startQueries() } }
            else  { print("HealthKit auth error:", err ?? "unknown") }
        }
    }

    // MARK: - Arranque
    private func startQueries() {
        startWorkoutSession()
        updateStepsToday()     // primera lectura: fija baseline
        startStepObserver()
    }

    // MARK: - Sesión HR en vivo
    private func startWorkoutSession() {
        let cfg = HKWorkoutConfiguration()
        cfg.activityType = .other; cfg.locationType = .indoor
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: cfg)
            builder = session!.associatedWorkoutBuilder()
        } catch { print("Error creando workout →", error); return }

        session!.delegate = self
        builder!.delegate = self
        builder!.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: cfg)

        let t = Date()
        session!.startActivity(with: t)
        builder!.beginCollection(withStart: t) { _, e in
            if let e = e { print("Begin-collection error:", e) }
        }
    }

    func workoutSession(_ ws: HKWorkoutSession,
                        didFailWithError error: Error) {
        print("Workout session falló:", error)
    }

    func workoutBuilder(_ wb: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let qt = HKObjectType.quantityType(forIdentifier: .heartRate),
              collectedTypes.contains(qt),
              let stats = wb.statistics(for: qt),
              let qty   = stats.mostRecentQuantity()
        else { return }

        let bpm = qty.doubleValue(for: .count().unitDivided(by: .minute()))
        DispatchQueue.main.async {
            self.heartRate = bpm
            self.sendMetricsToPhone()
        }
    }

    // MARK: - Pasos
    private func startStepObserver() {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        let q = HKObserverQuery(sampleType: stepType,
                                predicate: nil) { [weak self] _, _, err in
            if err == nil { self?.updateStepsToday() }
        }
        healthStore.execute(q)
        healthStore.enableBackgroundDelivery(for: stepType,
                                             frequency: .immediate) { _, _ in }
    }

    private func updateStepsToday() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let startDay = Calendar.current.startOfDay(for: Date())
        let pred = HKQuery.predicateForSamples(withStart: startDay,
                                               end: Date(),
                                               options: .strictStartDate)

        let q = HKStatisticsQuery(quantityType: stepType,
                                  quantitySamplePredicate: pred,
                                  options: .cumulativeSum) { _, stats, _ in
            let totalSteps = Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)

            // Si aún no tenemos línea base, la fijamos
            if self.baselineSteps == nil { self.baselineSteps = totalSteps }

            // Pasos relativos = total - baseline, nunca negativos
            let relative = max(0, totalSteps - (self.baselineSteps ?? 0))

            DispatchQueue.main.async {
                self.stepCount = relative
                self.sendMetricsToPhone()
            }
        }
        healthStore.execute(q)
    }

    // MARK: - Enviar al iPhone
    private func sendMetricsToPhone() {
        WatchSessionManager.shared.send(metrics: [
            "heartRate": heartRate,
            "steps": stepCount,
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    // No-op delegate (requerido por protocolo)
    func workoutBuilderDidCollectEvent(_ wb: HKLiveWorkoutBuilder) {}
    func workoutSession(_ ws: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {}
}
