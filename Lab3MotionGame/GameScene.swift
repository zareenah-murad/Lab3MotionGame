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
    
    // MARK: Motion property
    let motion = CMMotionManager()
    
    // MARK: Create Sprites Functions
    let platformBlock = SKSpriteNode()
    let scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    var score:Int = 0 {
        willSet(newValue){
            DispatchQueue.main.async{
                self.scoreLabel.text = "Score: \(newValue)"
            }
        }
    }
    
    // MARK: View Hierarchy Functions
    // this is like out "View Did Load" function
    override func didMove(to view: SKView) {
        
        // delegate for the contact of objects
        physicsWorld.contactDelegate = self
        
        backgroundColor = SKColor.white
        
        // start motion for gravity
        self.startMotionUpdates()
        
        // make sides to the screen
        self.addSidesAndTop()
        
        // add some stationary blocks on left and right
        self.addStaticBlockAtPoint(CGPoint(x: size.width * 0.1, y: size.height * 0.25))
        self.addStaticBlockAtPoint(CGPoint(x: size.width * 0.9, y: size.height * 0.25))
        
        // add a spinning block
        self.addSpinningBlockAtPoint(CGPoint(x: size.width * 0.5, y: size.height * 0.35))
        
        // add in the interaction sprite
        self.addSpriteBottle()
        
        // add a scorer
        self.addScore()
        
        // update a special watched property for score
        self.score = 0
    }
    

    
    func addScore(){
        
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = SKColor.blue
        // place score in middle of screen horizontally, and a littel above the minimum vertical
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.minY+20)
        
        addChild(scoreLabel)
    }
    
    
    func addSpriteBottle(){
        let spriteA = SKSpriteNode(imageNamed: "sprite")
        
        spriteA.size = CGSize(width:size.width*0.1,
                              height:size.height * 0.1)
        
        let randNumber = random(min: CGFloat(0.1), max: CGFloat(0.9))
        spriteA.position = CGPoint(x: size.width * randNumber,
                                   y: size.height * 0.75)
        
        spriteA.physicsBody = SKPhysicsBody(rectangleOf:spriteA.size)
        spriteA.physicsBody?.restitution = random(min: CGFloat(1.0),
                                                  max: CGFloat(1.5))
        spriteA.physicsBody?.isDynamic = true
        // for collision detection we need to setup these masks
        spriteA.physicsBody?.contactTestBitMask = 0x00000001
        spriteA.physicsBody?.collisionBitMask = 0x00000001
        spriteA.physicsBody?.categoryBitMask = 0x00000001
        
        self.addChild(spriteA)
    }
    
    func addSpinningBlockAtPoint(_ point:CGPoint){
        
        platformBlock.color = UIColor.red
        platformBlock.size = CGSize(width:size.width*0.15,height:size.height * 0.05)
        platformBlock.position = point
        
        
        platformBlock.physicsBody = SKPhysicsBody(rectangleOf:platformBlock.size)
        platformBlock.physicsBody?.contactTestBitMask = 0x00000001
        platformBlock.physicsBody?.collisionBitMask = 0x00000001
        platformBlock.physicsBody?.categoryBitMask = 0x00000001
        platformBlock.physicsBody?.isDynamic = true
        platformBlock.physicsBody?.pinned = false
        platformBlock.physicsBody?.affectedByGravity = false
        platformBlock.physicsBody?.mass = 100000
        
        self.addChild(platformBlock)

    }
    
    func addStaticBlockAtPoint(_ point:CGPoint){
        let 🔲 = SKSpriteNode()
        
        🔲.color = UIColor.red
        🔲.size = CGSize(width:size.width*0.1,height:size.height * 0.05)
        🔲.position = point
        
        🔲.physicsBody = SKPhysicsBody(rectangleOf:🔲.size)
        🔲.physicsBody?.isDynamic = true
        🔲.physicsBody?.pinned = true
        🔲.physicsBody?.allowsRotation = true
        
        self.addChild(🔲)
        
    }
    
    func addSidesAndTop(){
        let left = SKSpriteNode()
        let right = SKSpriteNode()
        let top = SKSpriteNode()
        
        left.size = CGSize(width:size.width*0.1,height:size.height)
        left.position = CGPoint(x:0, y:size.height*0.5)
        
        right.size = CGSize(width:size.width*0.1,height:size.height)
        right.position = CGPoint(x:size.width, y:size.height*0.5)
        
        top.size = CGSize(width:size.width,height:size.height*0.1)
        top.position = CGPoint(x:size.width*0.5, y:size.height)
        
        for obj in [left,right,top]{
            obj.color = UIColor.red
            obj.physicsBody = SKPhysicsBody(rectangleOf:obj.size)
            obj.physicsBody?.isDynamic = true
            obj.physicsBody?.pinned = true
            obj.physicsBody?.allowsRotation = false
            self.addChild(obj)
        }
    }
    
}


extension GameScene: SKPhysicsContactDelegate{
    
    
    // here is an inherited function from SKScene
    // this is called ANYTIME someone lifts a touch from the screen
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.addSpriteBottle()
    }
    
    // MARK: ===== Contact Delegate Functions=====
    func didBegin(_ contact: SKPhysicsContact) {
        // if anything interacts with the spin Block, then we should update the score
        if contact.bodyA.node == platformBlock || contact.bodyB.node == platformBlock {
            self.score += 1
        }
        
        // TODO: How might we add additional scoring mechanisms?
    }
}


extension GameScene{
    // MARK: Raw Motion Functions
    func startMotionUpdates(){
        // if motion is available, start updating the device motion
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 0.2
            self.motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: self.handleMotion )
        }
    }
    
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        // make gravity in the game als the simulator gravity
        if let gravity = motionData?.gravity {
            self.physicsWorld.gravity = CGVector(dx: CGFloat(9.8*gravity.x), dy: CGFloat(9.8*gravity.y))
        }
        
        
        // BONUS: using the acceleration to update node positions
        // Is this a good idea to do? Is it Easy to control?
        if let userAccel = motionData?.userAcceleration{
            
            
            if (platformBlock.position.x < 0 && userAccel.x < 0) || (platformBlock.position.x > self.size.width && userAccel.x > 0)
            {
                // do not update the position
                return
            }
            let action = SKAction.moveBy(x: userAccel.x*100, y: 0, duration: 0.1)
            self.platformBlock.run(action, withKey: "temp")
            // TODO: as a class, make these into buttons

        }
    }
    
    // MARK: Utility Functions (thanks ray wenderlich!)
    // generate some random numbers for cor graphics floats
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(Int.max))
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
}
