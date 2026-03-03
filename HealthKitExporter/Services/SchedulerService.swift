import Foundation

actor SchedulerService {
    private var task: Task<Void, Never>?

    func start(interval: Duration, operation: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task {
            // Run immediately on start
            await operation()
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                if !Task.isCancelled {
                    await operation()
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
