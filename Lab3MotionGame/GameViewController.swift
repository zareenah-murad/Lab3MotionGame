//
//  GameViewController.swift
//  Lab3MotionGame
//
//  Created by Zareenah Murad on 10/17/24.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    var gameScene: GameScene? // Add reference to GameScene
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup game scene
        gameScene = GameScene(size: view.bounds.size) // Assign the game scene to the variable
        let skView = view as! SKView // The view in storyboard must be an SKView
        skView.showsFPS = true // Show some debugging of the FPS
        skView.showsNodeCount = true // Show how many active objects are in the scene
        skView.ignoresSiblingOrder = true // Don't track who entered scene first
        gameScene?.scaleMode = .resizeFill
        skView.presentScene(gameScene) // Present the stored game scene
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop the background music if navigating away from the game view
        gameScene?.stopBackgroundMusic()
    }

    // Hide the status bar
    override var prefersStatusBarHidden : Bool {
        return true
    }
}
