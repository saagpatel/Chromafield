import XCTest
@testable import Chromafield

final class FrameBudgetMonitorTests: XCTestCase {

    func testOverBudgetWhenAllFramesSlow() {
        var monitor = FrameBudgetMonitor()
        for _ in 0..<60 {
            monitor.push(20.0)
        }
        XCTAssertTrue(monitor.isOverBudget)
        XCTAssertEqual(monitor.averageFrameTimeMs, 20.0, accuracy: 0.001)
    }

    func testUnderBudgetWhenAllFramesFast() {
        var monitor = FrameBudgetMonitor()
        for _ in 0..<60 {
            monitor.push(10.0)
        }
        XCTAssertFalse(monitor.isOverBudget)
        XCTAssertEqual(monitor.averageFrameTimeMs, 10.0, accuracy: 0.001)
    }

    func testExactlyAtThresholdIsNotOverBudget() {
        var monitor = FrameBudgetMonitor()
        for _ in 0..<60 {
            monitor.push(14.0)
        }
        XCTAssertFalse(monitor.isOverBudget, "Exactly at threshold (14.0) should not be over budget")
    }

    func testJustAboveThresholdIsOverBudget() {
        var monitor = FrameBudgetMonitor()
        for _ in 0..<60 {
            monitor.push(14.01)
        }
        XCTAssertTrue(monitor.isOverBudget)
    }

    func testRingBufferOverwritesOldValues() {
        var monitor = FrameBudgetMonitor()
        for _ in 0..<60 {
            monitor.push(20.0)
        }
        XCTAssertTrue(monitor.isOverBudget)

        for _ in 0..<60 {
            monitor.push(8.0)
        }
        XCTAssertFalse(monitor.isOverBudget)
        XCTAssertEqual(monitor.averageFrameTimeMs, 8.0, accuracy: 0.001)
    }

    func testPartialFillUsesActualCount() {
        var monitor = FrameBudgetMonitor()
        monitor.push(10.0)
        monitor.push(20.0)
        XCTAssertEqual(monitor.averageFrameTimeMs, 15.0, accuracy: 0.001)
    }

    func testEmptyMonitorReturnsZero() {
        let monitor = FrameBudgetMonitor()
        XCTAssertEqual(monitor.averageFrameTimeMs, 0.0)
        XCTAssertFalse(monitor.isOverBudget)
    }

    func testResetClearsAllData() {
        var monitor = FrameBudgetMonitor()
        for _ in 0..<60 {
            monitor.push(20.0)
        }
        XCTAssertTrue(monitor.isOverBudget)

        monitor.reset()
        XCTAssertEqual(monitor.averageFrameTimeMs, 0.0)
        XCTAssertFalse(monitor.isOverBudget)
    }
}
