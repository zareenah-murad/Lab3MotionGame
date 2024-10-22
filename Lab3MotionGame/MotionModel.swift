//
//  MotionModel.swift
//  Lab3MotionGame
//
//  Created by Alexandra Geer on 10/20/24.
//

import CoreMotion

protocol MotionDelegate {
    // Define delegate functions
    func activityUpdated(activity: CMMotionActivity)
    func pedometerUpdated(pedData: CMPedometerData, yesterdaySteps: Int)
}

class MotionModel {
    
    // MARK: =====Class Variables=====
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    var delegate: MotionDelegate? = nil
    
    // MARK: =====Motion Methods=====
    func startActivityMonitoring() {
        if CMMotionActivityManager.isActivityAvailable() {
            self.activityManager.startActivityUpdates(to: OperationQueue.main) { activity in
                if let unwrappedActivity = activity, let delegate = self.delegate {
                    delegate.activityUpdated(activity: unwrappedActivity)
                }
            }
        }
    }
    
    func startPedometerMonitoring() {
        if CMPedometer.isStepCountingAvailable() {
            // Start today's pedometer updates
            pedometer.startUpdates(from: Date()) { pedData, error in
                if let unwrappedPedData = pedData, let delegate = self.delegate {
                    // Fetch yesterday's steps
                    self.getYesterdaySteps { yesterdaySteps in
                        delegate.pedometerUpdated(pedData: unwrappedPedData, yesterdaySteps: yesterdaySteps)
                    }
                }
            }
        }
    }
    
    // Helper method to fetch yesterday's steps
    private func getYesterdaySteps(completion: @escaping (Int) -> Void) {
        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: now)
        let startOfYesterday = Calendar.current.date(byAdding: .day, value: -1, to: startOfToday)!
        
        pedometer.queryPedometerData(from: startOfYesterday, to: startOfToday) { pedData, error in
            if let pedData = pedData {
                completion(pedData.numberOfSteps.intValue)
            } else {
                completion(0)
            }
        }
    }
}
