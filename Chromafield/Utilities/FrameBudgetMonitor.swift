import Foundation

struct FrameBudgetMonitor: Sendable {
    private var frameTimes: [Double]
    private var writeIndex: Int
    private var count: Int
    private let capacity: Int
    private let threshold: Double

    init(capacity: Int = 60, threshold: Double = 14.0) {
        self.capacity = capacity
        self.threshold = threshold
        self.frameTimes = [Double](repeating: 0.0, count: capacity)
        self.writeIndex = 0
        self.count = 0
    }

    mutating func push(_ frameTimeMs: Double) {
        frameTimes[writeIndex] = frameTimeMs
        writeIndex = (writeIndex + 1) % capacity
        if count < capacity {
            count += 1
        }
    }

    var averageFrameTimeMs: Double {
        guard count > 0 else { return 0.0 }
        var sum = 0.0
        for i in 0..<count {
            sum += frameTimes[i]
        }
        return sum / Double(count)
    }

    var isOverBudget: Bool {
        averageFrameTimeMs > threshold
    }

    mutating func reset() {
        frameTimes = [Double](repeating: 0.0, count: capacity)
        writeIndex = 0
        count = 0
    }
}
