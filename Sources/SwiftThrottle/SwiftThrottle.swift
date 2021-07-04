//
//  SwiftThrottle.swift
//  Twitter @Lakr233
//
//  Created by Lakr Aream on 12/12/20.
//

import Foundation

/*

 This throttle is intended to prevent the program from crashing with
 too many requests or is used for saving computer resources.

 ** Swift Throttle is not designed for operations that require high time accuracy **

 */

public class Throttle {
    /// lock when dispatch job to execution
    internal var executeLock = NSLock()

    /// lock when setting job block item
    private var _assignmentLock = NSLock()
    internal var _assignment: (() -> Void)?
    internal var assignment: (() -> Void)? {
        set {
            _assignmentLock.lock()
            defer { _assignmentLock.unlock() }
            _assignment = newValue
        }
        get {
            _assignmentLock.lock()
            defer { _assignmentLock.unlock() }
            return _assignment
        }
    }

    /// Setup with these values to control the throttle behave
    internal var minimumDelay: TimeInterval
    internal var workingQueue: DispatchQueue
    internal var lastExecute: Date?
    internal var lastRequestWasCanceled: Bool = false
    internal var scheduled: Bool = false

    /// Create a throttle
    /// - Parameters:
    ///   - minimumDelay: in second
    ///   - queue: the queue that job will executed on, default to main
    public init(minimumDelay delay: TimeInterval,
                queue: DispatchQueue = DispatchQueue.main)
    {
        minimumDelay = delay
        workingQueue = queue

        #if DEBUG
            if minimumDelay < 0.1 {
                debugPrint("[SwiftThrottle] minimumDelay less then 0.1s will be inaccurate")
            }
        #endif
    }
}
