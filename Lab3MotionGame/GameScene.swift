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
    
    var previousPositionX: CGFloat = 0.0  // track phone's previous position for smoothing
    var filterFactor: CGFloat = 0.9  // factor for low-pass filter
    
    
    // MARK: Create Sprites Functions
    let minion = SKSpriteNode()
    let scoreLabel = SKLabelNode(fontNamed: "American Typewriter")
    var score:Int = 0 {
        willSet(newValue){
            DispatchQueue.main.async{
                self.scoreLabel.text = "Score: \(newValue)"
            }
        }
    }
    
    override func didMove(to view: SKView) {
        // Set up the physics world delegate
        physicsWorld.contactDelegate = self
        
        // Adjust gravity to make bananas/bombs fall slower
            physicsWorld.gravity = CGVector(dx: 0.0, dy: -3.0)

            
        // background color
        backgroundColor = SKColor.white
            
        // start motion for minion movement
        self.startMotionUpdates()
            
        // add the minion
        self.addMinion()
        
        // add the invisible ground
        self.addGround()
            
        let dropItemAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run {
                // randomly decide whether to drop a banana or a bomb
                // 80% bananas, 20% bombs
                let randomNumber = Int.random(in: 1...100)
                if randomNumber <= 80 {
                    self.addBanana()
                } else {
                    self.addBomb()
                }
            },
            SKAction.wait(forDuration: 2.0)
        ]))
        self.run(dropItemAction)

        
        // add score system
        self.addScore()
        self.score = 0
    }
    

    
    func addScore(){
        // Create background box for the score label
        let scoreBackground = SKSpriteNode(color: SKColor.black, size: CGSize(width: 200, height: 50))
        scoreBackground.position = CGPoint(x: frame.midX, y: frame.minY + 50)
        scoreBackground.zPosition = 1  // Ensure it's behind the score label
        
        // Create the score label
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
        return CGFloat(arc4random_uniform(UInt32(max - min))) + min
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



