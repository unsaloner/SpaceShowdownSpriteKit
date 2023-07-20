//
//  GameScene.swift
//  Space Showdown
//
//  Created by Unsal Oner on 10.07.2023.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene {
    
    var backgroundMusic : AVAudioPlayer?
    var shotMusic: AVAudioPlayer?

    
    private var gameTime = 0.0
    var scoreLabel = SKLabelNode(fontNamed: "Copperplate")
    var bestScoreLabel = SKLabelNode (fontNamed: "Copperplate")
    var livesLabel = SKLabelNode(fontNamed: "Copperplate")
    var heartNodes = [SKSpriteNode]()
    
    
    var remainingLives = 3 {
        didSet{
            livesLabel.text = "Lives: \(remainingLives)"
        }
    }
    
    var bestScore = 0 {
        didSet {
            bestScoreLabel.text = "Best Score: \(bestScore)"
        }
        
    }
    var score = 0 {
        didSet{
            scoreLabel.text = "Score: \(score)"
            scoreLabel.run(SKAction.sequence([SKAction.scale(to: 1.1, duration: 0.10),SKAction.scale(to: 1.0, duration: 0.18)]))
        }
    }
    var dynamicLinearDampening = CGFloat(9.0)
    
    var gameStarted = false
      
    override func sceneDidLoad() {
        loadBackground()
        setLives()
        setScoreLabel()
        setBestScoreLabel()
        loadStartButton()
        loadPauseButton()
        loadResumeButton()
        
        
    }
    
    override func didMove(to view: SKView) {
        loadBackgroundMusic()

        bestScore = ScoreManager.shared.loadBestScore()
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    func touchUp(atPoint pos : CGPoint) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        DispatchQueue.main.async {
            for t in touches {
                
                let touchedNodes = self.nodes(at: t.location(in: self))
                
                for touchedSprite in touchedNodes {
                    
                    if(touchedSprite.name == "Alien"){
                        touchedSprite.physicsBody = nil
                        touchedSprite.removeAllChildren()
                        touchedSprite.name = "removedAssaults"
                        
                        let alienBubble = self.addSpaceship(position:touchedSprite.position)
                        let waitForBubbleHelp = SKAction.wait(forDuration: 0.25)
                        let moveAlien = SKAction.moveTo(y: self.frame.maxY + 100, duration: 3)
                        let wait = SKAction.wait(forDuration: 1)
                        let removeAlien = SKAction.removeFromParent()
                        let guardiansOfPeaceSequence = SKAction.sequence([waitForBubbleHelp, moveAlien, wait, removeAlien])
                                            
                        touchedSprite.run(guardiansOfPeaceSequence)
                        alienBubble.run(guardiansOfPeaceSequence)
                        if self.gameStarted == true {
                            self.score += 1
                        }
                        self.updateDifficulty()
                        
                        break // don't save multiple items at once
                    }
                    else if touchedSprite.name == "ships" {
                        let run = SKAction.moveBy(x: -100, y: CGFloat.random(in: -70.0..<70.0), duration: 0.18)
                        touchedSprite.run(run)
                    }
                    else if touchedSprite.name == "startgame" {
                        touchedSprite.run(SKAction.sequence([SKAction.fadeOut(withDuration: 2),SKAction.removeFromParent()]))
                        self.gameStarted = true
                        self.remainingLives = 3
                    }else if touchedSprite.name == "replay" {
                        self.restartGame()
                    }else if touchedSprite.name == "pause" && self.gameStarted == true {
                        self.pauseGameScene()
                        self.pausedLabel()
                    }else if touchedSprite.name == "resume" && self.gameStarted == false{
                        self.resumeGameScene()
                        
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
 
    override func update(_ currentTime: TimeInterval) {
        
        DispatchQueue.main.async {
            // Called before each frame is rendered
            self.gameTime += 1.0
            if self.gameTime.truncatingRemainder(dividingBy: 60.0) == 0 {
                self.loadShips()
                
                if self.gameStarted == true && self.remainingLives > 0 {
                    self.addAliens()
                }else if self.remainingLives == 0 {
                    self.gameStarted = false
                    self.gameOver()
                }
            }
            self.alienYPosition()
        }
    }
    func alienYPosition(){
        // Alien'ın düşerken anlık y pozisyonunu kontrol et
        self.enumerateChildNodes(withName: "Alien") { node, _ in
                guard let alien = node as? SKSpriteNode else { return }
                if UIDevice.current.userInterfaceIdiom == .pad {
                    if alien.position.y < -300 {
                        // Alien ekranın dışına çıktı, remainingLives'ı eksilt
                        if self.remainingLives != 0 && self.gameStarted == true{
                            print(self.remainingLives)
                            print(alien.position.y)
                            self.remainingLives -= 1
                            self.setLives()
                            alien.removeFromParent()
                        }
                    }
                }else if UIDevice.current.userInterfaceIdiom == .phone{
                    if alien.position.y < -220 {
                        // Alien ekranın dışına çıktı, remainingLives'ı eksilt
                        if self.remainingLives != 0 && self.gameStarted == true{
                            print(self.remainingLives)
                            print(alien.position.y)
                            self.remainingLives -= 1
                            self.setLives()
                            alien.removeFromParent()
                        }
                    }
                }
            }
    }
    func randomXPosition() -> CGFloat {
        let position = CGFloat.random(in: (self.frame.minX + 50..<(self.frame.maxX-50)))
        return position
    }

    func gameOver(){

        let overButton = SKLabelNode(fontNamed: "Copperplate")
        overButton.text = "Game Over!"
        overButton.name = "gameover"
        overButton.fontSize = 75
        overButton.zPosition = 200
        overButton.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        scoreLabel.position = CGPoint(x: self.frame.midX , y: self.frame.midY - 20)
        if score > bestScore {
            bestScore = score
            ScoreManager.shared.saveBestScore(bestScore)
        }
        addChild(overButton)
        loadReplayButton()
    }
    
    
    func restartGame() {
        if UIDevice.current.userInterfaceIdiom == .pad{
            scoreLabel.position = CGPoint(x: frame.minX + 90 ,y: frame.minY + 420)
        }else {
            scoreLabel.position = CGPoint(x: frame.minX + 90 ,y: frame.minY + 500)
        }
        score = 0
        remainingLives = 3
        gameStarted = true
        dynamicLinearDampening = CGFloat(9.0)
        setLives()
        
        // Remove game over label
        enumerateChildNodes(withName: "gameover") { node, _ in
            node.removeFromParent()
        }
        // Remove aliens
        enumerateChildNodes(withName: "Alien") { node, _ in
            node.removeFromParent()
        }
        
        // Remove replay button
        enumerateChildNodes(withName: "replay") { node, _ in
            node.removeFromParent()
        }
    }
    
    @objc func pauseGameScene(){
        backgroundMusic?.stop()
        physicsWorld.speed = 0
        self.isPaused = true
        gameStarted = false
        
    }
    func resumeGameScene(){
        backgroundMusic?.play()
        physicsWorld.speed = 1
        self.isPaused = false
        self.gameStarted = true
//        Remove paused label
        enumerateChildNodes(withName: "pausedlabel") { node, _ in
            node.removeFromParent()
        }
    }

    
    func setLives(){
        for heart in heartNodes {
            heart.removeFromParent()
        }
        heartNodes.removeAll()
            let heartTexture = SKTexture(imageNamed: "heart")
            let heartSpacing: CGFloat = 40 // Kalp simgeleri arasındaki boşluk
            
            for i in 0..<remainingLives {
                let heart = SKSpriteNode(texture: heartTexture)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    heart.position = CGPoint(x: -350 + CGFloat(i) * heartSpacing, y: 235)
                }else {
                    heart.position = CGPoint(x: -350 + CGFloat(i) * heartSpacing, y: frame.midY + 150)
                }
                
                heart.zPosition = 40
                addChild(heart)
                heartNodes.append(heart)
            }
    }

    func setBestScoreLabel(){
        
        if UIDevice.current.userInterfaceIdiom == .pad{
            bestScoreLabel.position = CGPoint(x: frame.minX + 450 ,y: frame.minY + 420)
        }else {
            bestScoreLabel.position = CGPoint(x: frame.minX + 550 ,y: frame.minY + 500)
        }
        bestScoreLabel.text = "Best Score: 0"
        bestScoreLabel.fontSize = 30
        bestScoreLabel.zPosition = 40
        addChild(bestScoreLabel)
    }
    
    func setScoreLabel(){
        if UIDevice.current.userInterfaceIdiom == .pad{
            scoreLabel.position = CGPoint(x: frame.minX + 90 ,y: frame.minY + 420)
        }else {
            scoreLabel.position = CGPoint(x: frame.minX + 90 ,y: frame.minY + 500)
        }
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 30
        scoreLabel.zPosition = 40
        addChild(scoreLabel)
    }
    func pausedLabel(){
        let pausedLabel = SKLabelNode(fontNamed: "Copperplate")
            pausedLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
            pausedLabel.text = "PAUSED"
            pausedLabel.name = "pausedlabel"
            pausedLabel.fontSize = 125
            pausedLabel.zPosition = 200
            addChild(pausedLabel)
        
    }
    func updateDifficulty() {
        if score > 200 {
            dynamicLinearDampening = CGFloat(2.0)
        }else if score > 100 {
            dynamicLinearDampening = CGFloat(3.0)
        }else if score > 85 {
            dynamicLinearDampening = CGFloat(4.3)
        }else if score > 70 {
            dynamicLinearDampening = CGFloat(5.0)
        }else if score > 50 {
            dynamicLinearDampening = CGFloat(6.0)
        }else if score > 25 {
            dynamicLinearDampening = CGFloat(7.0)
        }else if score > 15 {
            dynamicLinearDampening = CGFloat(8.0)
        }
    }
    func addSpaceship(position: CGPoint) -> SKSpriteNode {
        let spaceship = SKSpriteNode(imageNamed: "spaceship3")
        spaceship.name = "bubble"
        spaceship.zPosition = 24
        spaceship.position = CGPoint(x: 0, y: -380)
        spaceship.size = CGSize(width: 70, height: 70)
        let fireLightSaber = SKAction.move(to: position, duration: 0.25)
        spaceship.run(fireLightSaber)
        
            
            if let soundURL = Bundle.main.url(forResource: "shotmusic", withExtension: "mp3") {
                do {
                    shotMusic = try AVAudioPlayer(contentsOf: soundURL)
                    shotMusic?.prepareToPlay()
                    shotMusic?.play()
                } catch {
                    print("Failed to load sound file: \(error.localizedDescription)")
                }
            } else {
                print("Sound file not found")
            }
        addChild(spaceship)
        return spaceship
        
    }
//    MARK: PARTICLES
    
    func addParticle(parentNode: SKSpriteNode){
        let fires = SKEmitterNode(fileNamed: "MyParticle")!
        fires.name = "fire"
        fires.zPosition = 1
        fires.position = CGPoint(x: 45, y: 0)
        parentNode.addChild(fires)
    }
    func addParticle2(parentNode:SKSpriteNode){
        let fires = SKEmitterNode(fileNamed: "MyParticle2")!
        fires.name = "fire"
        fires.zPosition = 19
        fires.position = CGPoint(x: 0, y: 0)
        parentNode.addChild(fires)
    }
    
    func addAliens(){
        if gameStarted == true && remainingLives != 0{
            let alien = SKSpriteNode(imageNamed: "alien")
            alien.name = "Alien"
            alien.zPosition = 20
            alien.position = CGPoint(x: randomXPosition(), y: frame.maxY + 50)
            alien.size = CGSize(width: 50, height: 50)
            alien.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "alien"), size: CGSize(width: 100, height: 100))
            alien.physicsBody?.isDynamic = true
            alien.physicsBody?.linearDamping = dynamicLinearDampening
            alien.physicsBody?.collisionBitMask = 1
            alien.physicsBody?.restitution = 1.0
            alien.physicsBody?.mass = 0.1
            alien.physicsBody?.allowsRotation = true
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -3..<3), duration: 10)
            alien.run(rotate)

            addParticle2(parentNode: alien)
            addChild(alien)
        }
        
        
    }
// MARK: LOADS
    func loadBackground(){
        let spaceBackground = SKSpriteNode(imageNamed: "background")
        spaceBackground.position = CGPoint(x: 0, y: 0)
        spaceBackground.zPosition = 0
        spaceBackground.xScale = 1
        spaceBackground.yScale = 1
        addChild(spaceBackground)
    }
    func loadBackgroundMusic() {
        
        guard let musicURL = Bundle.main.url(forResource: "backgroundmusic", withExtension: "mp3") else {
                return
            }
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: musicURL)
                audioPlayer.numberOfLoops = -1
                audioPlayer.prepareToPlay()
                audioPlayer.play()
                
                backgroundMusic = audioPlayer

            } catch {
                print("Müzik çalma hatası: \(error.localizedDescription)")
            }
    }
    
    func loadShips(){
        let ships = [
        "ship",
        "ship2",
        "ship3"
        ]
        let ship = SKSpriteNode(imageNamed: ships.randomElement()!)
        ship.name = "ships"
        ship.position = CGPoint(x: 410, y: CGFloat.random(in: -230..<230))
        let size = CGFloat.random(in: 50..<70)
        ship.size = CGSize(width: 70, height: size)
        ship.zPosition = 1
        
//        add animation
        let flyLeft = SKAction.moveTo(x: -450.0, duration: TimeInterval.random(in: 7..<18))
        let flySequence = SKAction.sequence([flyLeft,SKAction.removeFromParent()])
        ship.run(flySequence)
        
        let flyUp = SKAction.moveBy(x: 0.0, y: -20, duration: TimeInterval.random(in: 0.9..<1.5))
        let flyDown = SKAction.moveBy(x: 0.0, y: 20, duration: TimeInterval.random(in: 0.9..<1.5))
        let flyUpDownSequence = SKAction.sequence([flyUp,flyDown])
        let flyingUpDownRepeat = SKAction.repeatForever(flyUpDownSequence)
        ship.run(flyingUpDownRepeat)
        
        //        more animations
        let shipScale = SKAction.scaleX(to: 1.1, duration: 0.2)
        let shipReverseScale = SKAction.scaleX(to: 1.0, duration: 0.2)
        let scalingSequence = SKAction.sequence([shipScale,shipReverseScale])
        let repeatScale = SKAction.repeatForever(scalingSequence)
        ship.run(repeatScale)
        
        addParticle(parentNode: ship)
        addChild(ship)
    }
    
    func loadReplayButton(){
        let replayButton = SKLabelNode(fontNamed: "Copperplate")
            replayButton.text = "TRY AGAIN!"
            replayButton.name = "replay"
            replayButton.fontSize = 60
            replayButton.zPosition = 200
            replayButton.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 100)
            addChild(replayButton)
    }
    func loadStartButton() {
        let button = SKLabelNode(fontNamed: "Copperplate")
        button.text = "Start Game!"
        button.name = "startgame"
        button.fontSize = 75
        button.zPosition = 200
        button.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        addChild(button)
        
    }
    
    func loadPauseButton() {
        let pauseButton = SKSpriteNode(imageNamed: "pause_icon")
        pauseButton.name = "pause"
        pauseButton.setScale(0.2)
        pauseButton.zPosition = 40
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            pauseButton.position = CGPoint(x: self.frame.maxX - 70, y: self.frame.maxY - 430)
        } else {
            pauseButton.position = CGPoint(x: self.frame.midX + 300 , y: self.frame.midY + 150)
        }
        
        addChild(pauseButton)
    }
    func loadResumeButton(){
        let resumeButton = SKSpriteNode(imageNamed: "resume_icon")
        resumeButton.name = "resume"
        resumeButton.setScale(0.2)
        resumeButton.zPosition = 40
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            resumeButton.position = CGPoint(x: self.frame.maxX - 30, y: self.frame.maxY - 430)
        } else {
            resumeButton.position = CGPoint(x: self.frame.midX + 340 , y: self.frame.midY + 150)
        }
        
        addChild(resumeButton)
    }
}
private class ScoreManager {
    static let shared = ScoreManager()
    
    private let bestScoreKey = "BestScore"
    
    private init() {}
    
    func saveBestScore(_ score: Int) {
        UserDefaults.standard.set(score, forKey: bestScoreKey)
    }
    
    func loadBestScore() -> Int {
        return UserDefaults.standard.integer(forKey: bestScoreKey)
    }
}

