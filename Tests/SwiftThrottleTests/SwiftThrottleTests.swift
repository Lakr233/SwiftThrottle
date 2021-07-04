@testable import SwiftThrottle
import XCTest

/// Indicates how long the test will run
let multithreadThreshold = 30

final class SwiftThrottleTests: XCTestCase {
    /// Test the throttle
    func test() {
        print("[XCT] Starting test \(#file) \(#function)")

        var testShouldTerminate = false

        let sem = DispatchSemaphore(value: 0)
        let totalTestTime = Double(multithreadThreshold)
        let emitter: Double = 0.1

        // controller
        DispatchQueue.global(qos: .background).async {
            var sec: Double = 1
            while sec < totalTestTime {
                print("Throttle is testing in background... \(sec)/\(totalTestTime)s")
                sec += 1
                sleep(1)
            }
            print("Terminating throttle test...")
            testShouldTerminate = true
            sleep(1)
            sem.signal()
        }

        var results = [Int]()
        let results_lock = NSLock()
        DispatchQueue.global(qos: .background).async {
            let cpuCount = ProcessInfo().processorCount
            XCTAssert(cpuCount > 0,
                      "this test must be performed on a machine that has at least 1 cpu core")

            var dispatch = 0
            while dispatch < cpuCount {
                // worker

                let name = "ThrottleTest.\(dispatch)"
                let queue = DispatchQueue(label: name, attributes: .concurrent) // just in case
                let throttle = Throttle(minimumDelay: emitter, queue: DispatchQueue(label: name + ".worker"))
                print("Throttle test is starting test thread \(name)")
                queue.async {
                    var hit = 0
                    while !testShouldTerminate {
                        throttle.throttle { hit += 1 }
                    }
                    results_lock.lock()
                    results.append(hit)
                    results_lock.unlock()
                }
                dispatch += 1
            }
        }

        sem.wait()

        print("Throttle thread safe test completed")
        XCTAssert(results.count > 0)
        print("Throttle executed for \(results) times")

        print("Throttle test completed")

        /*

         ---

         Throttle thread safe test completed
         Throttle executed for [303, 303, 303, 0, 0, 0, 0, 303] times
         Throttle test completed
         Test Case '-[SwiftThrottleTests.SwiftThrottleTests test]' passed (31.281 seconds).
         Test Suite 'SwiftThrottleTests' passed at 2021-07-04 17:52:11.745.
              Executed 1 test, with 0 failures (0 unexpected) in 31.281 (31.281) seconds
         Test Suite 'SwiftThrottleTests.xctest' passed at 2021-07-04 17:52:11.747.
              Executed 1 test, with 0 failures (0 unexpected) in 31.281 (31.283) seconds
         Test Suite 'Selected tests' passed at 2021-07-04 17:52:11.748.
              Executed 1 test, with 0 failures (0 unexpected) in 31.281 (31.284) seconds

         ---

         -> Throttle executed for [303, 303, 303, 0, 0, 0, 0, 303] times

         this shows that you will still need to handle GCD concurrency in your app in a right way
         this is not a bug

         */        
    }
}
