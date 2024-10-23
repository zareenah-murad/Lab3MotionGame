//
//  GameScene.swift
//  Lab3MotionGame
//
//  Created by Zareenah Murad on 10/17/24.
//

import UIKit
import SpriteKit
import CoreMotion
import AVFoundation // Import AVFoundation for audio playback

class GameScene: SKScene {
    
    // MARK: Motion property
    let motion = CMMotionManager()
    
    var isPausedGame = false // To check if the game is paused
    let pauseButton = SKSpriteNode(imageNamed: "pause.png") // Load the pause.png image
    var backgroundMusicPlayer: AVAudioPlayer? // For background music
    
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
    
    var isGameStarted = false // To check if the game has started
    
    // MARK: View Hierarchy Functions
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
        
        // Display instructions at the start
        showInstructions()

        // Start playing the background music
        playBackgroundMusic()
    }
    
    // MARK: Play Background Music
    func playBackgroundMusic() {
        if let musicURL = Bundle.main.url(forResource: "Wii Music - Gaming Background Music (HD)", withExtension: "mp3") {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                backgroundMusicPlayer?.numberOfLoops = -1  // Loop indefinitely
                backgroundMusicPlayer?.volume = 0.3  // Set the volume to 30%
                backgroundMusicPlayer?.play()
            } catch {
                print("Error loading background music: \(error)")
            }
        }
    }

    
    // MARK: Stop Background Music
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
    }

    // MARK: Add Pause Button with Shadow (Only in the game)
    func addPauseButton() {
        // Set up the pause button itself
        pauseButton.size = CGSize(width: 40, height: 40) // Adjust the size
        pauseButton.position = CGPoint(x: size.width - 50, y: size.height - 100) // Position same as shadow
        pauseButton.name = "pauseButton"
        pauseButton.zPosition = 10 // In front of the shadow

        // Add the pause button to the scene
        addChild(pauseButton)
    }
    
    // MARK: Instructions Screen
    func showInstructions() {
        // Create background for the instructions (black rounded rectangle)
        let instructionsBackground = SKShapeNode(rectOf: CGSize(width: self.size.width - 40, height: 300), cornerRadius: 20)
        instructionsBackground.fillColor = SKColor.black
        instructionsBackground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        instructionsBackground.zPosition = 10
        instructionsBackground.name = "instructionsBackground"
        addChild(instructionsBackground)
        
        // Add instructions label inside the black box
        let instructionsLabel = SKLabelNode(fontNamed: "American Typewriter")
        instructionsLabel.text = """
        Welcome to the Banana Catcher Game!
        
        Tilt your phone to move the minion left and right.
        Catch bananas to score points.
        If you miss a banana, you lose one point.
        Avoid the bombs, or the game will end.
        
        Good luck!
        """
        instructionsLabel.fontSize = 20
        instructionsLabel.fontColor = SKColor.white
        instructionsLabel.numberOfLines = 0
        instructionsLabel.preferredMaxLayoutWidth = self.size.width - 60  // Ensure the text fits inside the box
        instructionsLabel.horizontalAlignmentMode = .center  // Center align the text
        instructionsLabel.position = CGPoint(x: 0, y: 0)  // Centered vertically in the box
        instructionsLabel.verticalAlignmentMode = .center
        instructionsLabel.zPosition = 11
        instructionsBackground.addChild(instructionsLabel)
        
        // Add "Start Game" button (green rounded rectangle button)
        let startButtonBackground = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 20)
        startButtonBackground.fillColor = SKColor.green
        startButtonBackground.position = CGPoint(x: size.width / 2, y: size.height * 0.25) // Lower the Y position to 0.2 of screen height
        startButtonBackground.name = "startButton"
        startButtonBackground.zPosition = 10
        addChild(startButtonBackground)

        let startButtonLabel = SKLabelNode(fontNamed: "American Typewriter")
        startButtonLabel.text = "Start Game"
        startButtonLabel.fontSize = 30
        startButtonLabel.fontColor = SKColor.white
        startButtonLabel.position = CGPoint(x: 0, y: -10)
        startButtonLabel.zPosition = 11
        startButtonBackground.addChild(startButtonLabel)
    }

    
    // MARK: Remove Instructions and Start the Game
    func removeInstructionsAndStartGame() {
        // Remove the instructions and start button
        self.childNode(withName: "instructionsBackground")?.removeFromParent()
        self.childNode(withName: "startButton")?.removeFromParent()
        
        // Start the game
        isGameStarted = true
        
        // Add the minion sprite
        self.addMinion()
        
        // Add the invisible ground
        self.addGround()
        
        // Add the pause button after the game starts
        addPauseButton()

        // Schedule bananas and bombs to fall
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
        
        // Start motion updates for the minion
        self.startMotionUpdates()
    }
    
    
    // MARK: Handle Pause Action
    func handlePause() {
        isPausedGame = true
        self.isPaused = true // Pause the game
        
        // Lower the background music volume to 30% of the original level
        backgroundMusicPlayer?.setVolume(0.3, fadeDuration: 1.0)
        
        // Stop motion updates so minion doesn't move while paused
        self.motion.stopDeviceMotionUpdates()

        // Gray out the screen
        let grayOverlay = SKShapeNode(rectOf: self.size)
        grayOverlay.fillColor = SKColor(white: 0.0, alpha: 0.5) // 50% opacity gray
        grayOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        grayOverlay.name = "grayOverlay"
        grayOverlay.zPosition = 50 // Make sure it's above everything else
        addChild(grayOverlay)
        
        // Add "Resume" button (green)
        let resumeButton = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 20)
        resumeButton.fillColor = SKColor.green
        resumeButton.position = CGPoint(x: size.width / 2, y: size.height * 0.5)
        resumeButton.name = "resumeButton"
        resumeButton.zPosition = 51
        addChild(resumeButton)
        
        let resumeLabel = SKLabelNode(fontNamed: "American Typewriter")
        resumeLabel.text = "Resume"
        resumeLabel.fontSize = 30
        resumeLabel.fontColor = SKColor.white
        resumeLabel.position = CGPoint(x: 0, y: -10)
        resumeLabel.zPosition = 52
        resumeButton.addChild(resumeLabel)
        
        // Add "Start Over" button (yellow)
        let startOverButton = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 20)
        startOverButton.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0) // Yellow color
        startOverButton.position = CGPoint(x: size.width / 2, y: size.height * 0.4)
        startOverButton.name = "startOverButton"
        startOverButton.zPosition = 51
        addChild(startOverButton)
        
        let startOverLabel = SKLabelNode(fontNamed: "American Typewriter")
        startOverLabel.text = "Start Over"
        startOverLabel.fontSize = 30
        startOverLabel.fontColor = SKColor.white
        startOverLabel.position = CGPoint(x: 0, y: -10)
        startOverLabel.zPosition = 52
        startOverButton.addChild(startOverLabel)
    }


    // MARK: Resume Game
    func resumeGame() {
        isPausedGame = false
        self.isPaused = false // Resume the game
        
        // Restore the background music volume to its original level (100%)
        backgroundMusicPlayer?.setVolume(1.0, fadeDuration: 1.0)

        // Start motion updates again for the minion movement
        self.startMotionUpdates()

        // Remove gray overlay and buttons
        self.childNode(withName: "grayOverlay")?.removeFromParent()
        self.childNode(withName: "resumeButton")?.removeFromParent()
        self.childNode(withName: "startOverButton")?.removeFromParent()
    }



    // MARK: Restart Game
    func restartGame() {
        // Stop the background music and restart it
        backgroundMusicPlayer?.stop() // Stop the current music
        
        // Reload the background music from the beginning
        if let url = Bundle.main.url(forResource: "backgroundMusic", withExtension: "mp3") {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
                backgroundMusicPlayer?.play() // Start playing again
            } catch {
                print("Error loading background music: \(error)")
            }
        }

        // Restart the game by presenting a new scene
        let newScene = GameScene(size: self.size)
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(newScene, transition: transition)
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

    // MARK: Add banana
    func addBanana() {
        let bananaTexture = SKTexture(imageNamed: "banana")

        let aspectRatio = bananaTexture.size().height / bananaTexture.size().width
        
        let bananaWidth = size.width * 0.3  // Adjust width to 30% of screen width
        let bananaHeight = bananaWidth * aspectRatio
        
        // Create banana sprite with correct aspect ratio
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

    // MARK: Add bomb
    func addBomb() {
        let bombTexture = SKTexture(imageNamed: "bomb")

        let aspectRatio = bombTexture.size().height / bombTexture.size().width
            
        let bombWidth = size.width * 0.2  // Adjust width to 20% of screen width
        let bombHeight = bombWidth * aspectRatio
            
        // Create bomb sprite with correct aspect ratio
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
        
        // Increase the minion's size to 50% of the screen width (previously 40%)
        let minionWidth = size.width * 0.5  // Increased width to 50% of screen width
        let minionHeight = minionWidth * aspectRatio  // Maintain aspect ratio
        
        minion.size = CGSize(width: minionWidth, height: minionHeight)
        minion.texture = minionTexture
        minion.position = CGPoint(x: size.width * 0.5, y: size.height * 0.2)
        
        // Use a custom physics body with a narrower width and a slightly taller height
        let physicsBodyWidth = minion.size.width * 0.6  // Even narrower
        let physicsBodyHeight = minion.size.height * 1.1  // Slightly taller to detect collisions earlier
        
        minion.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: physicsBodyWidth, height: physicsBodyHeight))
        minion.physicsBody?.isDynamic = false
        minion.physicsBody?.affectedByGravity = false
        minion.physicsBody?.allowsRotation = false
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
        
        // Stop background music
        stopBackgroundMusic()
        
        // play winning sound
        playSound(named: "youWin.mp3")

        // Remove the pause button
        self.pauseButton.removeFromParent()

        // Create white background for "You Win" label
        let winLabelBackground = SKShapeNode(rectOf: CGSize(width: 250, height: 100), cornerRadius: 10)
        winLabelBackground.fillColor = SKColor.white
        winLabelBackground.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        winLabelBackground.zPosition = 1
        addChild(winLabelBackground)
        
        // Create "You Win" label
        let winLabel = SKLabelNode(fontNamed: "American Typewriter")
        winLabel.text = "You Win!"
        winLabel.fontSize = 40
        winLabel.fontColor = SKColor.green
        winLabel.position = CGPoint(x: 0, y: -winLabel.frame.height / 2)  // Center it vertically
        winLabel.horizontalAlignmentMode = .center
        winLabel.zPosition = 2
        winLabelBackground.addChild(winLabel)
        
        // Create background for Play Again button
        let playAgainBackground = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 20)
        playAgainBackground.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0) // Yellow color
        playAgainBackground.position = CGPoint(x: frame.midX, y: frame.midY - 40)
        playAgainBackground.name = "playAgainButton"
        playAgainBackground.zPosition = 10
        addChild(playAgainBackground)
        
        let playAgainLabel = SKLabelNode(fontNamed: "American Typewriter")
        playAgainLabel.text = "Play Again"
        playAgainLabel.fontSize = 30
        playAgainLabel.fontColor = SKColor.white
        playAgainLabel.position = CGPoint(x: 0, y: -10)
        playAgainLabel.zPosition = 11
        playAgainBackground.addChild(playAgainLabel)
        
        // Create background for Exit button
        let exitBackground = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 20)
        exitBackground.fillColor = SKColor.blue
        exitBackground.position = CGPoint(x: frame.midX, y: frame.midY - 100)
        exitBackground.name = "exitButton"
        exitBackground.zPosition = 10
        addChild(exitBackground)
        
        let exitLabel = SKLabelNode(fontNamed: "American Typewriter")
        exitLabel.text = "Exit"
        exitLabel.fontSize = 30
        exitLabel.fontColor = SKColor.white
        exitLabel.position = CGPoint(x: 0, y: -10)
        exitLabel.zPosition = 11
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

        // Stop background music
        stopBackgroundMusic()
        
        // play losing sound
        playSound(named: "youLose.mp3")

        // Remove the pause button
        self.pauseButton.removeFromParent()

        // Create white background for "Game Over" label
        let gameOverBackground = SKShapeNode(rectOf: CGSize(width: 250, height: 100), cornerRadius: 10)
        gameOverBackground.fillColor = SKColor.white
        gameOverBackground.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        gameOverBackground.zPosition = 1
        addChild(gameOverBackground)
        
        // Create "Game Over" label
        let gameOverLabel = SKLabelNode(fontNamed: "American Typewriter")
        gameOverLabel.text = "Game Over!"
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = SKColor.red
        gameOverLabel.position = CGPoint(x: 0, y: -gameOverLabel.frame.height / 2)  // Center it vertically
        gameOverLabel.horizontalAlignmentMode = .center
        gameOverLabel.zPosition = 2
        gameOverBackground.addChild(gameOverLabel)

        // Create background for Play Again button
        let playAgainBackground = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 20)
        playAgainBackground.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0) // Yellow color
        playAgainBackground.position = CGPoint(x: frame.midX, y: frame.midY - 40)
        playAgainBackground.name = "playAgainButton"
        playAgainBackground.zPosition = 10
        addChild(playAgainBackground)
        
        let playAgainLabel = SKLabelNode(fontNamed: "American Typewriter")
        playAgainLabel.text = "Play Again"
        playAgainLabel.fontSize = 30
        playAgainLabel.fontColor = SKColor.white
        playAgainLabel.position = CGPoint(x: 0, y: -10)
        playAgainLabel.zPosition = 11
        playAgainBackground.addChild(playAgainLabel)
        
        // Create background for Exit button
        let exitBackground = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 20)
        exitBackground.fillColor = SKColor.blue
        exitBackground.position = CGPoint(x: frame.midX, y: frame.midY - 100)
        exitBackground.name = "exitButton"
        exitBackground.zPosition = 10
        addChild(exitBackground)
        
        let exitLabel = SKLabelNode(fontNamed: "American Typewriter")
        exitLabel.text = "Exit"
        exitLabel.fontSize = 30
        exitLabel.fontColor = SKColor.white
        exitLabel.position = CGPoint(x: 0, y: -10)
        exitLabel.zPosition = 11
        exitBackground.addChild(exitLabel)
    }

}

// MARK: - SKPhysicsContactDelegate
extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
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

// MARK: - Motion Handling
extension GameScene {
    func startMotionUpdates() {
        if self.motion.isDeviceMotionAvailable {
            self.motion.deviceMotionUpdateInterval = 0.02
            self.motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: self.handleMotion)
        }
    }

    func handleMotion(_ motionData: CMDeviceMotion?, error: Error?) {
        guard let gravity = motionData?.gravity else { return }

        let newXPosition = minion.position.x + CGFloat(gravity.x * 50)  // Adjust sensitivity

        // Adjust the padding
        let leftPadding: CGFloat = 18
        let rightPadding: CGFloat = 18
            
        // Ensure the minion stays within the screen bounds
        if newXPosition >= leftPadding && newXPosition <= size.width - rightPadding {
            minion.position.x = newXPosition
        }

        if gravity.x > 0 && lastDirection <= 0 {
            minion.xScale = -1 // Flip right
            lastDirection = gravity.x
        } else if gravity.x < 0 && lastDirection >= 0 {
            minion.xScale = 1 // Flip left
            lastDirection = gravity.x
        }
    }
}

// MARK: - Touch Handling
extension GameScene {
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let nodesAtPoint = self.nodes(at: location)
            
            for node in nodesAtPoint {
                // Handle the "Pause" button during the game
                if node.name == "pauseButton" && !isPausedGame {
                    handlePause()
                }
                
                // Handle the "Resume" button in the pause menu
                if node.name == "resumeButton" && isPausedGame {
                    resumeGame()
                }

                // Handle the "Start Over" button in the pause menu
                if node.name == "startOverButton" && isPausedGame {
                    restartGame() // Restart and reset music
                }
                
                // Handle the "Start Game" button during the instructions screen
                if node.name == "startButton" && !isGameStarted {
                    removeInstructionsAndStartGame()
                }
                
                // Handle the "Play Again" button during the game over screen
                if node.name == "playAgainButton" && isGameStarted {
                    restartGame() // Restart and reset music
                }
                
                // Handle the "Exit" button to go back to the previous view
                if node.name == "exitButton" {
                    if let viewController = self.view?.window?.rootViewController as? UINavigationController {
                        viewController.popViewController(animated: true) // Navigate back in a navigation controller
                    } else {
                        self.view?.window?.rootViewController?.dismiss(animated: true, completion: nil) // Dismiss modally presented view controller
                    }
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


