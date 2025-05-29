import HealthKit
import Combine

final class HealthManager: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        let trash: Void = ()
    }
    
    static let shared = HealthManager()
    private let healthStore = HKHealthStore()
    
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    @Published var heartRate: Double = 0
    @Published var stepCount: Int = 0

    private override init() { super.init() }

    func requestAuthorization() {
        let readTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.workoutType()                     // ← leer workouts
        ]
        let shareTypes: Set = [
            HKObjectType.workoutType()                     // ← escribir workouts
        ]
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
            if success {
                DispatchQueue.main.async { self.startQueries() }
            } else {
                print("HealthKit auth error:", error ?? "unknown")
            }
        }
    }

    private func startQueries() {
        startWorkoutSession()
        updateStepsToday()
        startStepObserver()
    }

    // MARK: - Heart Rate Live
    private func startWorkoutSession() {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .indoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session!.associatedWorkoutBuilder()
        } catch {
            print("Error creando workout session: \(error)")
            return
        }

        session!.delegate = self
        builder!.delegate = self

        builder!.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: config
        )

        let startDate = Date()
        session!.startActivity(with: startDate)
        builder!.beginCollection(withStart: startDate) { success, error in
            if let e = error {
                print("Error al comenzar colección: \(e)")
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) { /* no-op */ }

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didFailWithError error: Error) {
        print("Workout session falló: \(error)")
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              collectedTypes.contains(hrType),
              let stats = workoutBuilder.statistics(for: hrType),
              let quantity = stats.mostRecentQuantity()
        else { return }
        let bpm = quantity.doubleValue(for: HKUnit(from: "count/min"))
        DispatchQueue.main.async { self.heartRate = bpm }
        DispatchQueue.main.async {
          self.heartRate = bpm
          // Enviar mensaje al iPhone
          WatchSessionManager.shared.send(metrics: [
            "heartRate": bpm,
            "steps": self.stepCount,
            "timestamp": Date().timeIntervalSince1970
          ])
        }
    }

    // MARK: - Step Count Observer
    private func startStepObserver() {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                self?.updateStepsToday()
            }
        }
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if !success {
                print("No se habilitó delivery background steps:", error ?? "")
            }
        }
    }

    private func updateStepsToday() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay,
                                                    end: Date(),
                                                    options: .strictStartDate)

        let sumQuery = HKStatisticsQuery(quantityType: type,
                                         quantitySamplePredicate: predicate,
                                         options: .cumulativeSum) { _, stats, _ in
            let steps = Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            DispatchQueue.main.async { self.stepCount = steps }
            DispatchQueue.main.async {
              self.stepCount = steps
              // Envía también aquí para que iPhone reciba la actualización
              WatchSessionManager.shared.send(metrics: [
                "heartRate": self.heartRate,
                "steps": steps,
                "timestamp": Date().timeIntervalSince1970
              ])
            }
        }
        healthStore.execute(sumQuery)
    }
}
