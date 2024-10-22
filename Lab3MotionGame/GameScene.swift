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
    
    var previousPositionX: CGFloat = 0.0  // Track phone's previous position for smoothing
    var filterFactor: CGFloat = 0.9  // Factor for low-pass filter
    
    // Track the current direction to apply flipping
    var lastDirection: CGFloat = 0.0
    
    // Track which banana sound to play
    var isFirstSound = true

    
    // MARK: Create Sprites Functions
    let minion = SKSpriteNode()
    let scoreLabel = SKLabelNode(fontNamed: "American Typewriter")
    var score: Int = 0 {
        willSet(newValue){
            DispatchQueue.main.async{
                self.scoreLabel.text = "Score: \(newValue)"
            }
        }
    }
    
    // MARK: View Hierarchy Functions
    // this is like out "View Did Load" function
    override func didMove(to view: SKView) {
        
        // Set the background image
        let background = SKSpriteNode(imageNamed: "picnic-bg.jpg")
        background.size = CGSize(width: self.size.width, height: self.size.height)
        background.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        background.zPosition = -1  // Ensure the background is behind everything
        self.addChild(background)
        
        // Set up physics world
        physicsWorld.contactDelegate = self
        
        // Adjust gravity to make bananas/bombs fall slower
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -3.0)
        
        // Start motion updates for the minion
        self.startMotionUpdates()
        
        // Add the minion sprite
        self.addMinion()
        
        // Add the invisible ground
        self.addGround()
        
        // Schedule bananas and bombs to fall, 70% bananas and 30% bombs
        let dropItemAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run {
                let randomNumber = Int.random(in: 1...100)
                if randomNumber <= 70 {
                    self.addBanana()
                } else {
                    self.addBomb()
                }
            },
            SKAction.wait(forDuration: 2.0)
        ]))
        self.run(dropItemAction)
        
        // Add score system
        self.addScore()
        self.score = 0
    }
    

    
    // MARK: Add Score
    func addScore() {
        let scoreBackground = SKSpriteNode(color: SKColor.black, size: CGSize(width: 200, height: 50))
        scoreBackground.position = CGPoint(x: frame.midX, y: frame.minY + 50)
        scoreBackground.zPosition = 1
        
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = CGPoint(x: 0, y: -10)
        scoreLabel.zPosition = 2
        
        scoreBackground.addChild(scoreLabel)
        addChild(scoreBackground)
    }

    
    func addBanana() {
        let bananaTexture = SKTexture(imageNamed: "banana")

        let aspectRatio = bananaTexture.size().height / bananaTexture.size().width
        let bananaWidth = size.width * 0.3  // Adjust width to 30% of screen width
        let bananaHeight = bananaWidth * aspectRatio

        let banana = SKSpriteNode(texture: bananaTexture)
        banana.size = CGSize(width: bananaWidth, height: bananaHeight)

        // Generate a random position at the top
        let randomX = CGFloat.random(in: bananaWidth / 2...(size.width - bananaWidth / 2))  // Random X within screen bounds
        banana.position = CGPoint(x: randomX, y: size.height * 0.9)  // Top of the screen
                    
        // Set up the physics body for falling
        banana.physicsBody = SKPhysicsBody(rectangleOf: banana.size)
        banana.physicsBody?.restitution = 0.2  // Less bouncy for realism
        banana.physicsBody?.isDynamic = true
        banana.physicsBody?.contactTestBitMask = 0x00000001
        banana.physicsBody?.collisionBitMask = 0x00000001
        banana.physicsBody?.categoryBitMask = 0x00000001
        banana.name = "banana"
        
        self.addChild(banana)
    }


    func addBomb() {
        let bombTexture = SKTexture(imageNamed: "bomb")

        let aspectRatio = bombTexture.size().height / bombTexture.size().width
        let bombWidth = size.width * 0.2  // Adjust width to 20% of screen width
        let bombHeight = bombWidth * aspectRatio

        let bomb = SKSpriteNode(texture: bombTexture)
        bomb.size = CGSize(width: bombWidth, height: bombHeight)

        // Generate random position at the top
        let randomX = CGFloat.random(in: bombWidth / 2...(size.width - bombWidth / 2))  // Random X within screen bounds
        bomb.position = CGPoint(x: randomX, y: size.height * 0.9)  // Top of the screen

        // Set up the physics body for falling
        bomb.physicsBody = SKPhysicsBody(rectangleOf: bomb.size)
        bomb.physicsBody?.restitution = 0.2
        bomb.physicsBody?.isDynamic = true
        bomb.physicsBody?.contactTestBitMask = 0x00000001
        bomb.physicsBody?.collisionBitMask = 0x00000001
        bomb.physicsBody?.categoryBitMask = 0x00000002
        bomb.name = "bomb"
        
        self.addChild(bomb)
    }


    // MARK: Add Minion
    func addMinion() {
        let minionTexture = SKTexture(imageNamed: "minion")
        let aspectRatio = minionTexture.size().height / minionTexture.size().width
        
        let minionWidth = size.width * 0.4
        let minionHeight = minionWidth * aspectRatio
        
        minion.size = CGSize(width: minionWidth, height: minionHeight)
        minion.texture = minionTexture
        minion.position = CGPoint(x: size.width * 0.5, y: size.height * 0.2)
        
        // Use a custom physics body with a narrower width and a slightly taller height
        let physicsBodyWidth = minion.size.width * 0.6  // Even narrower
        let physicsBodyHeight = minion.size.height * 1.1  // Slightly taller to detect collisions earlier

        minion.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: physicsBodyWidth, height: physicsBodyHeight))
        minion.physicsBody?.isDynamic = false  // Ensure the minion doesn't move
        minion.physicsBody?.affectedByGravity = false  // Ensure gravity does not affect the minion
        minion.physicsBody?.allowsRotation = false  // Prevent rotation
        minion.physicsBody?.contactTestBitMask = 0x00000001
        minion.physicsBody?.collisionBitMask = 0x00000001
        minion.physicsBody?.categoryBitMask = 0x00000001
        minion.name = "minion"
        
        self.addChild(minion)
    }


    
    // create invisible ground to detect when a banana is missed
    // deduct points if a banana collides with ground
    func addGround() {
        let ground = SKSpriteNode(color: .clear, size: CGSize(width: size.width, height: 10))
        ground.position = CGPoint(x: size.width / 2, y: 0)  // Positioned at the bottom of the screen
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = 0x00000004
        ground.physicsBody?.contactTestBitMask = 0x00000001
        ground.name = "ground"
        
        self.addChild(ground)
    }
    
    func displayMessage(_ message: String) {
        // Create a background label
        let messageBackground = SKSpriteNode(color: SKColor.lightGray, size: CGSize(width: 300, height: 50))
        messageBackground.position = CGPoint(x: frame.midX, y: frame.midY + 200)
        messageBackground.zPosition = 1
        addChild(messageBackground)
        
        // Create a label for the message
        let messageLabel = SKLabelNode(fontNamed: "American Typewriter")
        messageLabel.text = message
        messageLabel.fontSize = 24
        messageLabel.fontColor = SKColor.white
        messageLabel.position = CGPoint(x: 0, y: -messageLabel.frame.height / 2)  // Center it vertically within the background
        messageLabel.horizontalAlignmentMode = .center  // Ensure text is centered horizontally
        messageLabel.zPosition = 2
        messageBackground.addChild(messageLabel)
        
        // Add fade out effect and remove from parent after fade
        let fadeOutAction = SKAction.fadeOut(withDuration: 2.0)
        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeOutAction, removeAction])
        
        messageBackground.run(sequence)
    }

    func playAlternateCatchSound() {
        if isFirstSound {
            playSound(named: "catchBanana.mp3")
        } else {
            playSound(named: "catchBanana2.mp3")
        }
        
        // Toggle the boolean for the next time
        isFirstSound.toggle()
    }

    
    func checkWinCondition() {
        if self.score >= 10 {
            self.winGame()
        }
    }
    
    func winGame() {
        // Stop all actions
        self.removeAllActions()

        // Stop minion movement by stopping motion updates
        self.motion.stopDeviceMotionUpdates()
        
        // play winning sound
        playSound(named: "youWin.mp3")

        // Create a more muted green background for "You Win" label
        let winBackground = SKSpriteNode(color: SKColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1.0), size: CGSize(width: 250, height: 80))
        winBackground.position = CGPoint(x: frame.midX, y: frame.midY + 80) // Higher position
        winBackground.zPosition = 1
        self.addChild(winBackground)
        
        // Create "You Win" label (smaller size, centered vertically)
        let winLabel = SKLabelNode(fontNamed: "American Typewriter")
        winLabel.text = "You Win!"
        winLabel.fontSize = 35
        winLabel.fontColor = SKColor.white
        winLabel.position = CGPoint(x: 0, y: -winLabel.frame.height / 2)
        winLabel.horizontalAlignmentMode = .center
        winLabel.zPosition = 2
        winBackground.addChild(winLabel)
        
        // Add Play Again button with purple background
        let playAgainBackground = SKSpriteNode(color: SKColor.purple, size: CGSize(width: 200, height: 50))
        playAgainBackground.position = CGPoint(x: frame.midX, y: frame.midY - 10)  // Position adjusted
        playAgainBackground.name = "playAgainButton"
        playAgainBackground.zPosition = 1
        self.addChild(playAgainBackground)
        
        let playAgainLabel = SKLabelNode(fontNamed: "American Typewriter")
        playAgainLabel.text = "Play Again"
        playAgainLabel.fontSize = 30
        playAgainLabel.fontColor = SKColor.white
        playAgainLabel.position = CGPoint(x: 0, y: -10)
        playAgainLabel.zPosition = 2
        playAgainBackground.addChild(playAgainLabel)
        
        // Add Exit button with blue background
        let exitBackground = SKSpriteNode(color: SKColor.blue, size: CGSize(width: 200, height: 50))
        exitBackground.position = CGPoint(x: frame.midX, y: frame.midY - 60)  // Position adjusted
        exitBackground.name = "exitButton"
        exitBackground.zPosition = 1
        self.addChild(exitBackground)
        
        let exitLabel = SKLabelNode(fontNamed: "American Typewriter")
        exitLabel.text = "Exit"
        exitLabel.fontSize = 30
        exitLabel.fontColor = SKColor.white
        exitLabel.position = CGPoint(x: 0, y: -10)
        exitLabel.zPosition = 2
        exitBackground.addChild(exitLabel)
    }
    
    func checkGameOver() {
        if self.score < 0 {
            self.gameOver()
        }
    }
    
    func gameOver() {
        // Stop all actions
        self.removeAllActions()

        // Stop minion movement by stopping motion updates
        self.motion.stopDeviceMotionUpdates()
        
        // play losing sound
        playSound(named: "youLose.mp3")

        // Create opaque red background for "Game Over" label
        let gameOverBackground = SKSpriteNode(color: SKColor.red, size: CGSize(width: 250, height: 80))
        gameOverBackground.position = CGPoint(x: frame.midX, y: frame.midY + 80) // Higher position
        gameOverBackground.zPosition = 1
        self.addChild(gameOverBackground)
        
        // Create "Game Over" label (smaller size, centered vertically)
        let gameOverLabel = SKLabelNode(fontNamed: "American Typewriter")
        gameOverLabel.text = "Game Over!"
        gameOverLabel.fontSize = 35
        gameOverLabel.fontColor = SKColor.white
        gameOverLabel.position = CGPoint(x: 0, y: -gameOverLabel.frame.height / 2)
        gameOverLabel.horizontalAlignmentMode = .center
        gameOverLabel.zPosition = 2
        gameOverBackground.addChild(gameOverLabel)

        // Add Play Again button with purple background
        let playAgainBackground = SKSpriteNode(color: SKColor.purple, size: CGSize(width: 200, height: 50))
        playAgainBackground.position = CGPoint(x: frame.midX, y: frame.midY - 10)  // Position adjusted
        playAgainBackground.name = "playAgainButton"
        playAgainBackground.zPosition = 1
        self.addChild(playAgainBackground)
        
        let playAgainLabel = SKLabelNode(fontNamed: "American Typewriter")
        playAgainLabel.text = "Play Again"
        playAgainLabel.fontSize = 30
        playAgainLabel.fontColor = SKColor.white
        playAgainLabel.position = CGPoint(x: 0, y: -10)
        playAgainLabel.zPosition = 2
        playAgainBackground.addChild(playAgainLabel)
        
        // Add Exit button with blue background
        let exitBackground = SKSpriteNode(color: SKColor.blue, size: CGSize(width: 200, height: 50))
        exitBackground.position = CGPoint(x: frame.midX, y: frame.midY - 60)  // Position adjusted
        exitBackground.name = "exitButton"
        exitBackground.zPosition = 1
        self.addChild(exitBackground)
        
        let exitLabel = SKLabelNode(fontNamed: "American Typewriter")
        exitLabel.text = "Exit"
        exitLabel.fontSize = 30
        exitLabel.fontColor = SKColor.white
        exitLabel.position = CGPoint(x: 0, y: -10)
        exitLabel.zPosition = 2
        exitBackground.addChild(exitLabel)
    }


    
}


// MARK: - SKPhysicsContactDelegate
extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Handle banana and minion collision (banana caught)
        if (contact.bodyA.node?.name == "banana" && contact.bodyB.node?.name == "minion") ||
           (contact.bodyA.node?.name == "minion" && contact.bodyB.node?.name == "banana") {
            self.score += 1
            if contact.bodyA.node?.name == "banana" {
                contact.bodyA.node?.removeFromParent()
            } else if contact.bodyB.node?.name == "banana" {
                contact.bodyB.node?.removeFromParent()
            }
            displayMessage("Banana Acquired!")  // Show the message
            playAlternateCatchSound()  // Alternate between the two banana sounds
            self.checkWinCondition()
        }

        
        // Handle banana hitting the ground (banana missed)
        if (contact.bodyA.node?.name == "banana" && contact.bodyB.node?.name == "ground") ||
           (contact.bodyA.node?.name == "ground" && contact.bodyB.node?.name == "banana") {
            self.score -= 1
            if contact.bodyA.node?.name == "banana" {
                contact.bodyA.node?.removeFromParent()
            } else if contact.bodyB.node?.name == "banana" {
                contact.bodyB.node?.removeFromParent()
            }
            displayMessage("Banana Missed!")  // Show the message
            playSound(named: "missedBanana.mp3")  // Play the sound
            self.checkGameOver()  // Check if the score goes below 0 after deduction
        }


        // Handle hitting a bomb
        if (contact.bodyA.node?.name == "bomb" && contact.bodyB.node?.name == "minion") ||
           (contact.bodyA.node?.name == "minion" && contact.bodyB.node?.name == "bomb") {
            if contact.bodyA.node?.name == "bomb" {
                contact.bodyA.node?.removeFromParent()
            } else if contact.bodyB.node?.name == "bomb" {
                contact.bodyB.node?.removeFromParent()
            }
            displayMessage("Hit Bomb!")  // Show the message
            playSound(named: "hitBomb.mp3")  // Play the sound
            
            // Add a delay to allow the sound to play before game over
            let delay = SKAction.wait(forDuration: 0.1)
            let triggerGameOver = SKAction.run {
                self.gameOver()
            }
                
            // Run the actions in sequence
            self.run(SKAction.sequence([delay, triggerGameOver]))
        }

    }


}


extension GameScene{
    // MARK: Raw Motion Functions
    func startMotionUpdates() {
        if self.motion.isDeviceMotionAvailable {
            self.motion.deviceMotionUpdateInterval = 0.02
            self.motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: self.handleMotion)
        }
    }
    
    // Handle the motion data for left-right movement
    func handleMotion(_ motionData: CMDeviceMotion?, error: Error?) {
        guard let gravity = motionData?.gravity else { return }
        
        // Calculate the new X position based on gravity.x
        let newXPosition = minion.position.x + CGFloat(gravity.x * 50)  // Adjust sensitivity here
        
        // Adjust the padding
        let leftPadding: CGFloat = 18
        let rightPadding: CGFloat = 18
            
        // Ensure the minion stays within the screen bounds
        if newXPosition >= leftPadding && newXPosition <= size.width - rightPadding {
            minion.position.x = newXPosition
        }
        
        // Flip the minion image based on the tilt direction
        if gravity.x > 0 && lastDirection <= 0 {
            minion.xScale = -1 // Flip horizontally when moving right
            lastDirection = gravity.x
        } else if gravity.x < 0 && lastDirection >= 0 {
            minion.xScale = 1 // Flip back when moving left
            lastDirection = gravity.x
        }
    }

    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let nodesAtPoint = self.nodes(at: location)
            
            for node in nodesAtPoint {
                if node.name == "playAgainButton" {
                    // Restart game by presenting a new scene
                    let newScene = GameScene(size: self.size)
                    let transition = SKTransition.fade(withDuration: 1.0)
                    self.view?.presentScene(newScene, transition: transition)
                } else if node.name == "exitButton" {
                    // Handle exit
                    // FIX MEEEEEEE
                    // want this exit button to go back to the step view
                    exit(0)  // This will close the app, replace as needed
                }
            }
        }
    }

    
    // MARK: Sound Effects!
    func playSound(named soundFileName: String) {
        let sound = SKAction.playSoundFileNamed(soundFileName, waitForCompletion: false)
        self.run(sound)
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

