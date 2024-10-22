//
//  GameViewController.swift
//  Lab3MotionGame
//
//  Created by Zareenah Murad on 10/17/24.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup game scene
        let scene = GameScene(size: view.bounds.size)
        let skView = view as! SKView // The view in storyboard must be an SKView
        skView.showsFPS = true // Show some debugging of the FPS
        skView.showsNodeCount = true // Show how many active objects are in the scene
        skView.ignoresSiblingOrder = true // Don't track who entered scene first
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    // Hide the status bar
    override var prefersStatusBarHidden : Bool {
        return true
    }
}
