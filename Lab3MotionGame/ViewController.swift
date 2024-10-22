//
//  ViewController.swift
//  Lab3MotionGame
//
//  Created by Alexandra Geer on 10/20/24.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    let motionModel = MotionModel()
    
    // MARK: ===== UI Elements =====
    @IBOutlet weak var todayStepsLabel: UILabel!
    @IBOutlet weak var yesterdayStepsLabel: UILabel!
    @IBOutlet weak var goalStepsLabel: UILabel!
    @IBOutlet weak var remainingStepsLabel: UILabel!
    @IBOutlet weak var activityLabel: UILabel!
    
    var circularProgressBar: CAShapeLayer!
    var circularProgressBarTrack: CAShapeLayer!
    
    var dailyStepGoal: Int = UserDefaults.standard.integer(forKey: "dailyStepGoal") {
        didSet {
            UserDefaults.standard.set(dailyStepGoal, forKey: "dailyStepGoal")
            updateStepGoalUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.motionModel.delegate = self
        self.motionModel.startActivityMonitoring()
        self.motionModel.startPedometerMonitoring()

        setupCircularProgressBar()
        updateStepGoalUI()
    }
    
    // MARK: ===== UI Setup Methods =====
    func setupCircularProgressBar() {
        // Define the center and the radius for the circle
        let center = view.center
        let radius: CGFloat = 100
        
        // Create the track layer (the background circle)
        circularProgressBarTrack = CAShapeLayer()
        let circularPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: -CGFloat.pi / 2, endAngle: 1.5 * CGFloat.pi, clockwise: true)
        circularProgressBarTrack.path = circularPath.cgPath
        circularProgressBarTrack.fillColor = UIColor.clear.cgColor
        circularProgressBarTrack.strokeColor = UIColor.lightGray.cgColor
        circularProgressBarTrack.lineWidth = 20
        circularProgressBarTrack.lineCap = .round
        view.layer.addSublayer(circularProgressBarTrack)
        
        // Create the progress layer (the filled circle)
        circularProgressBar = CAShapeLayer()
        circularProgressBar.path = circularPath.cgPath
        circularProgressBar.fillColor = UIColor.clear.cgColor
        circularProgressBar.strokeColor = UIColor.systemYellow.cgColor
        circularProgressBar.lineWidth = 20
        circularProgressBar.lineCap = .round
        circularProgressBar.strokeEnd = 0  // Initially no progress
        view.layer.addSublayer(circularProgressBar)
    }
    
    func setProgress(stepsToday: Int) {
        let progress = min(Float(stepsToday) / Float(dailyStepGoal), 1.0)
        circularProgressBar.strokeEnd = CGFloat(progress)
        
        // Optionally add animation for smoother transition
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.toValue = progress
        animation.duration = 0.5
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        circularProgressBar.add(animation, forKey: "progressAnim")
    }

    func updateStepGoalUI() {
        self.goalStepsLabel.text = "Goal: \(dailyStepGoal) steps"
    }

    func updateRemainingStepsUI(_ stepsToday: Int) {
        let remainingSteps = max(dailyStepGoal - stepsToday, 0)
        self.remainingStepsLabel.text = "Remaining: \(remainingSteps) steps"
    }
    
    @IBAction func setGoalPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Set Daily Step Goal", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter step goal"
            textField.keyboardType = .numberPad
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let goalText = alert.textFields?.first?.text, let goal = Int(goalText) {
                self.dailyStepGoal = goal
                self.updateStepGoalUI()
            }
        }
        
        alert.addAction(saveAction)
        self.present(alert, animated: true, completion: nil)
    }
}

extension ViewController: MotionDelegate {
    // MARK: ===== Motion Delegate Methods =====
    
    func activityUpdated(activity: CMMotionActivity) {
        DispatchQueue.main.async {
            if activity.walking {
                self.activityLabel.text = "Current Activity: Walking"
            } else if activity.running {
                self.activityLabel.text = "Current Activity: Running"
            } else if activity.cycling {
                self.activityLabel.text = "Current Activity: Cycling"
            } else if activity.automotive {
                self.activityLabel.text = "Current Activity: Driving"
            } else if activity.stationary {
                self.activityLabel.text = "Current Activity: Still"
            } else {
                self.activityLabel.text = "Current Activity: Unknown"
            }
        }
    }
    
    func pedometerUpdated(pedData: CMPedometerData, yesterdaySteps: Int) {
        DispatchQueue.main.async {
            let stepsToday = pedData.numberOfSteps.intValue
            self.todayStepsLabel.text = "Today: \(stepsToday) steps"
            self.yesterdayStepsLabel.text = "Yesterday: \(yesterdaySteps) steps"
            self.updateRemainingStepsUI(stepsToday)
            self.setProgress(stepsToday: stepsToday)
        }
    }
}
