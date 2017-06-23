//
//  GameScene.swift
//  Basics
//
//  Created by Darrell Payne on 6/19/17.
//  Copyright © 2017 Darrell Payne. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player:SKSpriteNode?
    var enemy:SKSpriteNode?
    var item:SKSpriteNode?
    var platform:SKSpriteNode?
    
    var label:SKLabelNode?
    var fireRate:TimeInterval = 0.5
    var timeSinceFire:TimeInterval = 0
    var lastTime:TimeInterval = 0
    var score:Int = 0
    var isTouching: Bool = false
    let noCategory:UInt32 = 0
    let laserCategory:UInt32 = 0b1
    let playerCategory:UInt32 = 0b1 << 1
    let enemyCategory:UInt32 = 0b1 << 2
    let itemCategory:UInt32 = 0b1 << 3
    let platformCategory:UInt32 = 0b1 << 4
    

    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        label = self.childNode(withName: "label") as? SKLabelNode
        
        player = self.childNode(withName: "player") as? SKSpriteNode
        player?.physicsBody?.categoryBitMask = playerCategory
        player?.physicsBody?.collisionBitMask = platformCategory // collides with platform
        player?.physicsBody?.contactTestBitMask = enemyCategory | itemCategory // notify on contact
        
        enemy = self.childNode(withName: "enemy") as? SKSpriteNode
        enemy?.physicsBody?.categoryBitMask = enemyCategory
        enemy?.physicsBody?.collisionBitMask = noCategory
        enemy?.physicsBody?.contactTestBitMask = playerCategory | laserCategory
        
        item = self.childNode(withName: "item") as? SKSpriteNode
        item?.physicsBody?.categoryBitMask = itemCategory
        item?.physicsBody?.collisionBitMask = noCategory
        item?.physicsBody?.contactTestBitMask = playerCategory
        
        platform = self.childNode(withName: "platform") as? SKSpriteNode
        platform?.physicsBody?.categoryBitMask = platformCategory
        platform?.physicsBody?.collisionBitMask = playerCategory
        platform?.physicsBody?.contactTestBitMask = noCategory
        
        let moveAction:SKAction = SKAction.moveBy(x: -200, y: 0, duration: 2)
        moveAction.timingMode = .easeInEaseOut
        let reversedAction:SKAction = moveAction.reversed()
        let sequence:SKAction = SKAction.sequence([moveAction,reversedAction])
        let repeatAction:SKAction = SKAction.repeatForever(sequence)
        item?.run(repeatAction, withKey: "itemMove")
        
        let frame1:SKTexture = SKTexture(imageNamed: "player_frame1")
        let frame2:SKTexture = SKTexture(imageNamed: "player_frame2")
        let frame3:SKTexture = SKTexture(imageNamed: "player_frame3")
        let frame4:SKTexture = SKTexture(imageNamed: "player_frame4")
        
        let animation:SKAction = SKAction.animate(with: [frame1,frame2,frame3,frame4], timePerFrame: 0.1)
        let repeatAnimation:SKAction = SKAction.repeatForever(animation)
        player?.run(repeatAnimation)

       
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let cA:UInt32 = contact.bodyA.categoryBitMask
        let cB:UInt32 = contact.bodyB.categoryBitMask
        
        if cA == playerCategory || cB == playerCategory {
            let otherNode:SKNode = (cA == playerCategory) ? contact.bodyB.node! : contact.bodyA.node!
            playerDidCollide(with: otherNode)
        }else {
            let explosion:SKEmitterNode = SKEmitterNode(fileNamed: "explosion")!
            explosion.position = contact.bodyA.node!.position
            self.addChild(explosion)
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
        }
        
    }
    
    func playerDidCollide (with other:SKNode){
        if other.parent == nil {
            return
        }
        let otherCategory = other.physicsBody?.categoryBitMask
        if otherCategory == itemCategory {
            let points:Int = other.userData?.value(forKey: "coins") as! Int
            score += points
            label?.text = "Score: \(score)"
            
            other.removeFromParent()
            
        } else if otherCategory == enemyCategory {
            other.removeFromParent()
            player?.removeFromParent()
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        let xpos = pos.x
        let ypos = player?.position.y
        player?.position = CGPoint(x: xpos, y: ypos!)
        item?.removeAction(forKey: "itemMove")
        
        
        isTouching = true
    }
    
    func jump() {
    }
    
    func touchMoved(toPoint pos : CGPoint) {

    }
    
    func touchUp(atPoint pos : CGPoint) {
        isTouching = false
//        player?.position = pos
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
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
        // Called before each frame is rendered
        if isTouching {
            player?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
        }
        checkLaser(currentTime - lastTime)
        lastTime = currentTime
        
    }
    
    func checkLaser(_ frameRate:TimeInterval){
        // add time to timer
        timeSinceFire += frameRate
        
        // return if it hasn't been enough time to fire laser
        if timeSinceFire < fireRate {
            return
        }
        
        // spawn laser
        spawnLaser()
        
        // reset timer
        timeSinceFire = 0
    }
    
    func spawnLaser(){
        let scene:SKScene = SKScene(fileNamed: "Laser")!
        let laser = scene.childNode(withName: "laser")!
        
        var pos: CGPoint = player!.position;
        pos.y += 25.0
        
        laser.position = pos
        laser.move(toParent: self)
        
        laser.physicsBody?.categoryBitMask = laserCategory
        laser.physicsBody?.collisionBitMask = noCategory
        laser.physicsBody?.contactTestBitMask = enemyCategory

    }
}
