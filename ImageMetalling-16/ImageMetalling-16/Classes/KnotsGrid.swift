//
//  KnotsGrid.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 06.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Cocoa
import SpriteKit 

open class KnotsGrid: SKShapeNode { 
    
    static public let fadeIn  = SKAction.fadeAlpha(to: 1, duration:0.05)
    static public let fadeOut = SKAction.fadeAlpha(to: 0.2, duration:0.15)
    static public let pulse   = SKAction.repeat(SKAction.sequence([fadeOut,fadeIn]), count: 2)
    
    static public let scaleIn    = SKAction.scale(to: 1, duration: 0.1)
    static public let scaleOut   = SKAction.scale(to: 1.3, duration: 0.1)
    static public let scalePulse = SKAction.repeat(SKAction.sequence([scaleOut,scaleIn]), count: 2)
    
    public var mlsPoints:MLSPoints
    
    public var box:NSRect { return  NSInsetRect(self.bounds, padding, padding) }
    public var bounds:NSRect { didSet{ update() } }
    public var radius:CGFloat { didSet{ update() } }
    public var padding:CGFloat { didSet{ update() } }
    
    public init(bounds: NSRect, dimension: (width:Int,height:Int), radius:CGFloat=5, padding:CGFloat=20) {
        mlsPoints = MLSPoints(dimension: dimension)
        self.bounds = bounds
        self.radius = radius
        self.padding = padding
        super.init()
        update()                
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isInitilized = false
    
    private let scalingFactor:CGFloat = 1
    
    public func reset() {
        mlsPoints.targets = [float2](mlsPoints.sources)
        removeAllChildren()
        isInitilized = false
        update()
    }    
    
    public func update() {
        var index = 0
        let box = self.box
                
        for y in 0..<mlsPoints.dimension.height {
            for x in 0..<mlsPoints.dimension.width {
                
                let p =  mlsPoints.target(to: box, at: (x: x, y: y)) 
        
                var knot:KnotNode
                if isInitilized {
                    knot = children[index] as! KnotNode
                    knot.bounds = box
                    if !knot.isPinned {
                        knot.position = p
                    }
                }                    
                else {
                    knot = KnotNode(bounds: box, radius: radius)
                    knot.position = p
                    knot.name = "\(index)"
                    addChild(knot)     
                    
                    if x == 0 && y == 0 {
                        knot.isPinned = true
                    }
                    else if x == 0 && y == mlsPoints.dimension.height-1 {
                        knot.isPinned = true
                    }
                    else if x == mlsPoints.dimension.width-1 && y == mlsPoints.dimension.height-1 {
                        knot.isPinned = true
                    }
                    else if x == mlsPoints.dimension.width-1 && y == 0 {
                        knot.isPinned = true
                    }                    
                }    
                index += 1
            }
        }
        isInitilized = true
    }
}
