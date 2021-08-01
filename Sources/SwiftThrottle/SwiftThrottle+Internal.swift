//
//  SwiftThrottle+Internal.swift
//  Twitter @Lakr233
//
//  Created by Lakr Aream on 12/12/20.
//

import Foundation

public extension Throttle {
    /// Update property minimumDelay
    /// - Parameter interval: in second
    func updateMinimumDelay(interval: Double) {
        executeLock.lock()
        minimumDelay = interval
        executeLock.unlock()
    }

    /// Assign job to throttle
    /// - Parameter job: call block
    func throttle(job: (() -> Void)?, useAssignment: Bool = false) {
        // if called from rescheduled job, cancel job overwrite
        var capturedJobDecision: (() -> Void)?
        if !useAssignment {
            // resign job every time calling from user
            assignment = job
            capturedJobDecision = job
        } else {
            capturedJobDecision = assignment
        }
        guard let capturedJob = capturedJobDecision else { return }

        // lock down every thing when resigning job
        executeLock.lock()
        defer { self.executeLock.unlock() }

        func executeCapturedBlock() {
            lastExecute = Date()
            workingQueue.async {
                capturedJob()
            }
        }

        // MARK: LOCK BEGIN

        if let lastExec = lastExecute {
            // executed before, value negative
            let timeBetween = -lastExec.timeIntervalSinceNow

            if timeBetween < minimumDelay {
                // The throttle will be reprogrammed once for future execution
                lastRequestWasCanceled = true
                if !scheduled {
                    scheduled = true
                    let dispatchTime = Double(minimumDelay - timeBetween + 0.01)
                    // Preventing trigger failures
                    // This is where the inaccuracy comes from
                    workingQueue.asyncAfter(deadline: .now() + dispatchTime) {
                        self.throttle(job: nil, useAssignment: true)
                        self.scheduled = false
                    }
                }
            } else {
                // Throttle release to execution
                executeCapturedBlock()
            }
        }
        else // never called before, release to execution
        {
            executeCapturedBlock()
        }

        // MARK: LOCK END
    }
}
