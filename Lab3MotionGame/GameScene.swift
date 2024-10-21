//
//  GameScene.swift
//  Lab3MotionGame
//
//  Created by Zareenah Murad on 10/17/24.
//

import UIKit
import SpriteKit
import CoreMotion

class GameScene: SKScene {
    
    // MARK: Properties
    let motion = CMMotionManager()
    let minionSprite = SKSpriteNode(imageNamed: "minion.png") // Minion sprite with basket
    let scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    
    var score: Int = 0 {
        willSet(newValue) {
            DispatchQueue.main.async {
                self.scoreLabel.text = "Score: \(newValue)"
            }
        }
    }
    
    override func didMove(to view: SKView) {
        // Set up the physics world delegate
        physicsWorld.contactDelegate = self
        
        backgroundColor = SKColor.white
        
        // Start CoreMotion for gravity-based movement
        startMotionUpdates()
        
        // Set up game elements
        addSidesAndTop() // Add screen edges
        addStaticBlocks() // Add stationary blocks
        addMinionSprite() // Add minion sprite with basket
        addScoreLabel() // Add score label
        
        score = 0 // Initialize score
    }
    
    // MARK: Add Minion Sprite
    func addMinionSprite() {
        // Set the size of the minion to maintain aspect ratio
        let originalMinionTexture = SKTexture(imageNamed: "minion.png")
        let minionAspectRatio = originalMinionTexture.size().width / originalMinionTexture.size().height
        
        // Adjust the height of the minion and calculate the corresponding width
        let minionHeight = size.height * 0.2 // Set the height to 20% of the screen height
        let minionWidth = minionHeight * minionAspectRatio // Maintain aspect ratio
        
        // Set the size and position of the minion
        minionSprite.size = CGSize(width: minionWidth, height: minionHeight)
        
        // Position the minion a little higher to avoid covering the score
        minionSprite.position = CGPoint(x: size.width * 0.5, y: size.height * 0.2)
        
        // Physics body for the minion
        minionSprite.physicsBody = SKPhysicsBody(rectangleOf: minionSprite.size)
        minionSprite.physicsBody?.isDynamic = true
        minionSprite.physicsBody?.affectedByGravity = false // No vertical movement due to gravity
        minionSprite.physicsBody?.allowsRotation = false // Prevent rotation
        
        addChild(minionSprite)
    }
    
    // MARK: Add Score Label
    func addScoreLabel() {
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = SKColor.blue
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.minY + 40)
        addChild(scoreLabel)
    }
    
    // MARK: Add Static Blocks
    func addStaticBlocks() {
        // Add some static blocks at the sides
        addStaticBlockAtPoint(CGPoint(x: size.width * 0.1, y: size.height * 0.25))
        addStaticBlockAtPoint(CGPoint(x: size.width * 0.9, y: size.height * 0.25))
    }
    
    func addStaticBlockAtPoint(_ point: CGPoint) {
        let block = SKSpriteNode()
        block.color = UIColor.red
        block.size = CGSize(width: size.width * 0.1, height: size.height * 0.05)
        block.position = point
        
        block.physicsBody = SKPhysicsBody(rectangleOf: block.size)
        block.physicsBody?.isDynamic = true
        block.physicsBody?.pinned = true
        block.physicsBody?.allowsRotation = true
        
        addChild(block)
    }
    
    // MARK: Add Sides and Top
    func addSidesAndTop() {
        let left = SKSpriteNode()
        let right = SKSpriteNode()
        let top = SKSpriteNode()
        
        left.size = CGSize(width: size.width * 0.1, height: size.height)
        left.position = CGPoint(x: 0, y: size.height * 0.5)
        
        right.size = CGSize(width: size.width * 0.1, height: size.height)
        right.position = CGPoint(x: size.width, y: size.height * 0.5)
        
        top.size = CGSize(width: size.width, height: size.height * 0.1)
        top.position = CGPoint(x: size.width * 0.5, y: size.height)
        
        for obj in [left, right, top] {
            obj.color = UIColor.red
            obj.physicsBody = SKPhysicsBody(rectangleOf: obj.size)
            obj.physicsBody?.isDynamic = true
            obj.physicsBody?.pinned = true
            obj.physicsBody?.allowsRotation = false
            addChild(obj)
        }
    }
    
    // MARK: Motion Control Functions
    func startMotionUpdates() {
        if self.motion.isDeviceMotionAvailable {
            self.motion.deviceMotionUpdateInterval = 0.1
            self.motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: self.handleMotion)
        }
    }
    
    // Handle the motion data for left-right movement
    func handleMotion(_ motionData: CMDeviceMotion?, error: Error?) {
        guard let gravity = motionData?.gravity else { return }
        
        // Map the gravity.x value to the horizontal position of the minion
        let newXPosition = minionSprite.position.x + CGFloat(gravity.x * 50) // Sensitivity control
        
        // Prevent the minion from moving off the screen (add bounds checking)
        if newXPosition >= minionSprite.size.width / 2 && newXPosition <= size.width - minionSprite.size.width / 2 {
            minionSprite.position.x = newXPosition
        }
    }
    
    // MARK: Utility Functions
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UInt32.max))
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
}

// MARK: - SKPhysicsContactDelegate
extension GameScene: SKPhysicsContactDelegate {
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Add the minion sprite again when touch ends (if needed for replay or game mechanics)
        self.addMinionSprite()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Update score when minion interacts with a platform or block
        if contact.bodyA.node == minionSprite || contact.bodyB.node == minionSprite {
            self.score += 1
        }
    }
}



