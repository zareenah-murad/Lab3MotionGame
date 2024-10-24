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
    @IBOutlet weak var timeUntilResetLabel: UILabel!
    
    var circularProgressBar: CAShapeLayer!
    var circularProgressBarTrack: CAShapeLayer!
    
    var dailyStepGoal: Int = UserDefaults.standard.integer(forKey: "dailyStepGoal") {
        didSet {
            UserDefaults.standard.set(dailyStepGoal, forKey: "dailyStepGoal")
            updateStepGoalUI()
        }
    }
    
    var stepsToday: Int = 0  // Keep track of the current step count
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.motionModel.delegate = self
        self.motionModel.startActivityMonitoring()
        self.motionModel.startPedometerMonitoring()
        
        // Set up a gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [UIColor.systemTeal.cgColor, UIColor.systemBlue.cgColor]
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Add Minion images
        addMinionImages()
        
        // Fetch steps for today and yesterday
        fetchStepsForToday()
        fetchYesterdaySteps()
        startRealTimeStepUpdates()
        
        // First, set up the circular progress bar
        setupCircularProgressBar()
        
        // Now customize circular progress bar with a gradient stroke
        let gradientStroke = CAGradientLayer()
        gradientStroke.frame = circularProgressBar.bounds
        gradientStroke.colors = [UIColor.systemYellow.cgColor, UIColor.systemGreen.cgColor]
        
        // Create a separate mask layer if necessary, but don't set the gradient layer as its own mask
        let maskLayer = CAShapeLayer()
        maskLayer.path = circularProgressBar.path  // Use the same path as the progress bar
        
        gradientStroke.mask = maskLayer  // Apply the mask to the gradient
        
        circularProgressBar.addSublayer(gradientStroke)  // Add gradient as a sublayer
        
        updateStepGoalUI()
        
        // Check if we need to reset steps at 6 a.m.
        checkForStepReset()
        
        // Immediately update the label with time until reset
        updateResetLabel()
        
        // Start the timer to update the "time until reset" label
        startTimerForResetCountdown()
    }
    
    // Function to fetch today's steps
    func fetchStepsForToday() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)  // Get midnight of the current day
        
        self.motionModel.pedometer.queryPedometerData(from: startOfDay, to: now) { pedData, error in
            if let pedData = pedData {
                DispatchQueue.main.async {
                    // This will ensure that we always have the correct step count from midnight
                    self.stepsToday = pedData.numberOfSteps.intValue
                    UserDefaults.standard.set(self.stepsToday, forKey: "stepsToday")  // Persist stepsToday
                    
                    // Update the UI
                    self.todayStepsLabel.text = "Today's Steps: \(self.stepsToday)"
                    self.setProgress(stepsToday: self.stepsToday)
                    self.updateRemainingStepsUI(self.stepsToday)
                }
            } else if let error = error {
                print("Error fetching today's steps: \(error)")
            }
        }
    }
    
    func startRealTimeStepUpdates() {
        guard CMPedometer.isStepCountingAvailable() else { return }

        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)  // Get midnight of the current day
        
        // Start receiving updates from the pedometer
        self.motionModel.pedometer.startUpdates(from: startOfDay) { pedData, error in
            if let pedData = pedData {
                DispatchQueue.main.async {
                    let newSteps = pedData.numberOfSteps.intValue
                    
                    // Do not add the previously stored steps, just update the current steps for today
                    self.stepsToday = newSteps
                    
                    // Persist updated steps
                    UserDefaults.standard.set(self.stepsToday, forKey: "stepsToday")
                    
                    // Update UI
                    self.todayStepsLabel.text = "Today's Steps: \(self.stepsToday)"
                    self.setProgress(stepsToday: self.stepsToday)
                    self.updateRemainingStepsUI(self.stepsToday)
                }
            } else if let error = error {
                print("Error updating steps: \(error)")
            }
        }
    }

    
    
    // Function to fetch yesterday's steps
    func fetchYesterdaySteps() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
              let endOfYesterday = calendar.date(byAdding: .second, value: -1, to: startOfToday) else {
            return
        }
        
        self.motionModel.pedometer.queryPedometerData(from: startOfYesterday, to: endOfYesterday) { pedData, error in
            if let pedData = pedData {
                DispatchQueue.main.async {
                    let yesterdaySteps = pedData.numberOfSteps.intValue
                    self.yesterdayStepsLabel.text = "Yesterday's Steps: \(yesterdaySteps)"
                }
            } else if let error = error {
                print("Error fetching yesterday's steps: \(error)")
            }
        }
    }
    
    
    func addMinionImages() {
        let minionImageNames = ["minionSticker1", "minionSticker2", "minionSticker3", "minionSticker4"]  // Replace these with actual asset names
        
        // Define specific x and y positions for each Minion image using fixed offsets from the edges
        let positions: [(xOffset: CGFloat, yOffset: CGFloat)] = [
            (xOffset: 150, yOffset: 400),  // First Minion's position
            (xOffset: -150, yOffset: 400),  // Second Minion's position
            (xOffset: 150, yOffset: -300),  // Third Minion's position
            (xOffset: -150, yOffset: -300)  // Fourth Minion's position
        ]
        
        for (index, imageName) in minionImageNames.enumerated() {
            if let minionImage = UIImage(named: imageName) {
                let minionImageView = UIImageView(image: minionImage)
                
                // Set a larger image size
                let imageSize: CGFloat = 110.0
                
                // Disable autoresizing masks for using Auto Layout
                minionImageView.translatesAutoresizingMaskIntoConstraints = false
                
                // Add the image view to the main view
                self.view.addSubview(minionImageView)
                
                // Apply constraints
                NSLayoutConstraint.activate([
                    // Set the width and height constraints for the Minion image
                    minionImageView.widthAnchor.constraint(equalToConstant: imageSize),
                    minionImageView.heightAnchor.constraint(equalToConstant: imageSize),
                    
                    // Position the image relative to the center of the view, but using offsets
                    minionImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: positions[index].xOffset),
                    minionImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: positions[index].yOffset)
                ])
                
                // Set content mode to aspect fit for scaling
                minionImageView.contentMode = .scaleAspectFit
            }
        }
    }
    
    // Function to check and reset steps at 6 a.m.
    func checkForStepReset() {
        let lastReset = UserDefaults.standard.object(forKey: "lastStepReset") as? Date ?? Date()
        let now = Date()
        
        if !Calendar.current.isDate(lastReset, inSameDayAs: now) && isPastResetTime() {
            stepsToday = 0  // Reset the step count
            UserDefaults.standard.set(now, forKey: "lastStepReset")  // Update the last reset time
            updateRemainingStepsUI(stepsToday)
            updateStepGoalUI()
        }
    }
    
    // Update the label immediately on view load
    func updateResetLabel() {
        let timeLeft = self.timeUntilNextReset()
        self.timeUntilResetLabel.text = String(format: "%02d Hrs, %02d Min \n Left to Reach Goal", timeLeft.hours, timeLeft.minutes)
    }
    
    // Helper function to check if the current time is past 6 a.m.
    func isPastResetTime() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let resetTime = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now)!
        return now >= resetTime
    }
    
    // Function to calculate the time remaining until 6 a.m. the next day
    func timeUntilNextReset() -> (hours: Int, minutes: Int) {
        let calendar = Calendar.current
        let now = Date()
        let nextReset = calendar.nextDate(after: now, matching: DateComponents(hour: 6), matchingPolicy: .nextTime)!
        let diff = Calendar.current.dateComponents([.hour, .minute], from: now, to: nextReset)
        return (hours: diff.hour ?? 0, minutes: diff.minute ?? 0)
    }
    
    // Start a timer to update the label every minute
    func startTimerForResetCountdown() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { timer in
            self.updateResetLabel()  // Update the label on each tick
        }
    }
    
    // MARK: ===== UI Setup Methods =====
    func setupCircularProgressBar() {
        let center = view.center
        let radius: CGFloat = 140  // You can adjust the radius if needed
        
        // Define the track layer (background circle)
        circularProgressBarTrack = CAShapeLayer()
        let circularPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: -CGFloat.pi / 2, endAngle: 1.5 * CGFloat.pi, clockwise: true)
        circularProgressBarTrack.path = circularPath.cgPath
        circularProgressBarTrack.fillColor = UIColor.clear.cgColor
        circularProgressBarTrack.strokeColor = UIColor.lightGray.cgColor
        
        // Increase the thickness by changing lineWidth (thicker than before)
        circularProgressBarTrack.lineWidth = 25  // Adjust this value for thickness
        circularProgressBarTrack.lineCap = .round
        view.layer.addSublayer(circularProgressBarTrack)
        
        // Define the progress layer (the filled circle)
        circularProgressBar = CAShapeLayer()
        circularProgressBar.path = circularPath.cgPath
        circularProgressBar.fillColor = UIColor.clear.cgColor
        circularProgressBar.strokeColor = UIColor.systemYellow.cgColor
        circularProgressBar.lineWidth = 30  // Match the thickness of the track layer
        circularProgressBar.lineCap = .round
        circularProgressBar.strokeEnd = 0  // Initially no progress
        
        // Add the progress layer to the view (temporarily without gradient)
        view.layer.addSublayer(circularProgressBar)
        
        // Create a gradient layer for the progress bar
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [UIColor.systemRed.cgColor, UIColor.systemYellow.cgColor, UIColor.systemGreen.cgColor]  // Adjust colors for gradient
        
        // Define the gradient locations (optional, can be tweaked)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        
        // Mask the gradient with the circular progress bar
        gradientLayer.mask = circularProgressBar
        
        // Add the gradient layer to the view
        view.layer.addSublayer(gradientLayer)
    }
    
    func setProgress(stepsToday: Int) {
        let progress = min(Float(stepsToday) / Float(dailyStepGoal), 1.0)
        circularProgressBar.strokeEnd = CGFloat(progress)
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.toValue = progress
        animation.duration = 0.5
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        circularProgressBar.add(animation, forKey: "progressAnim")
    }
    
    func updateStepGoalUI() {
        self.goalStepsLabel.text = " Daily Goal: \(dailyStepGoal) steps"
    }
    
    func updateRemainingStepsUI(_ stepsToday: Int) {
        let remainingSteps = max(dailyStepGoal - stepsToday, 0)
        self.remainingStepsLabel.text = "Steps Remaining: \(remainingSteps) steps"
    }
    
    @IBAction func setGoalPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Set Daily Step Goal", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter step goal"
            textField.keyboardType = .numberPad
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let goalText = alert.textFields?.first?.text, let newGoal = Int(goalText), newGoal > 0 {
                // Set the new daily step goal
                self.dailyStepGoal = newGoal
                
                // Only update the UI based on the new goal, without modifying stepsToday
                self.updateStepGoalUI()  // Update goal label UI
                self.updateRemainingStepsUI(self.stepsToday)  // Update remaining steps based on new goal
                self.setProgress(stepsToday: self.stepsToday)  // Update progress based on new goal
            } else {
                // Handle invalid goal input (e.g., zero or negative goal)
                let errorAlert = UIAlertController(title: "Invalid Goal", message: "Please enter a valid step goal.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(errorAlert, animated: true, completion: nil)
            }
        }
        
        alert.addAction(saveAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: ===== Play Game Button Action =====
    @IBAction func playGameButtonPressed(_ sender: UIButton) {
        // Check if the step goal is reached
        if stepsToday >= dailyStepGoal {
            // Trigger the segue manually using the identifier you set in the storyboard
            performSegue(withIdentifier: "gameSegue", sender: self)  // "gameSegue" is the segue identifier set in the storyboard
        } else {
            // Show alert if step goal is not reached
            let alert = UIAlertController(title: "Step Goal Not Reached", message: "You need to reach your daily step goal before playing the game.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
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
            self.stepsToday = pedData.numberOfSteps.intValue // Store the step count in a property
            self.todayStepsLabel.text = "Today's Steps: \(self.stepsToday) steps"
            self.yesterdayStepsLabel.text = "Yesterday's Steps: \(yesterdaySteps) steps"
            self.updateRemainingStepsUI(self.stepsToday)
            self.setProgress(stepsToday: self.stepsToday)
        }
    }
}
