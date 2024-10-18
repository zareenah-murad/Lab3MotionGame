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

        //setup game scene
        let scene = GameScene(size: view.bounds.size)
        let skView = view as! SKView // the view in storyboard must be an SKView
        skView.showsFPS = true // show some debugging of the FPS
        skView.showsNodeCount = true // show how many active objects are in the scene
        skView.ignoresSiblingOrder = true // don't track who entered scene first
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    
    // don't show the time and status bar at the top
    override var prefersStatusBarHidden : Bool {
        return true
    }
    


}