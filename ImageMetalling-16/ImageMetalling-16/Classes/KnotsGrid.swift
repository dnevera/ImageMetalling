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
    
    public var grouppingIndex = -1
    public var grouppingKnots:[Int:[KnotNode]] = [:]
    
    static public let fadeIn  = SKAction.fadeAlpha(to: 1, duration:0.05)
    static public let fadeOut = SKAction.fadeAlpha(to: 0.2, duration:0.15)
    static public let pulse   = SKAction.repeat(SKAction.sequence([fadeOut,fadeIn]), count: 2)
    
    static public let scaleIn    = SKAction.scale(to: 1, duration: 0.1)
    static public let scaleOut   = SKAction.scale(to: 1.3, duration: 0.1)
    static public let scalePulse = SKAction.repeat(SKAction.sequence([scaleOut,scaleIn]), count: 2)
    
    public var mesh:MLSMesh
    
    public var box:NSRect { return  NSInsetRect(self.bounds, padding, padding) }
    public var bounds:NSRect { didSet{ update() } }
    public var radius:CGFloat { didSet{ update() } }
    public var padding:CGFloat { didSet{ update() } }
    
    public init(bounds: NSRect, dimension: (width:Int,height:Int), radius:CGFloat=5, padding:CGFloat=20) {
        mesh = MLSMesh(dimension: dimension)
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
        mesh.reset()
        removeAllChildren()
        isInitilized = false
        grouppingIndex = -1
        grouppingKnots = [:]
        update()
    }    
    
    public func pinEdges() {
        var index = 0

        for y in 0..<mesh.dimension.height {
            for x in 0..<mesh.dimension.width {
                let knot = children[index] as! KnotNode
                if x == 0 || y == 0 {
                    knot.isPinned = true
                }
                if x == mesh.dimension.width-1 || y == mesh.dimension.height-1 {
                    knot.isPinned = true
                }
                index += 1
            }
        }
            
    }
    
    public func update(_ newTargets:[float2]? = nil) {
        
        if let t = newTargets {
            mesh.reset(t)
        }
        
        var index = 0
        let box = self.box
                
        for y in 0..<mesh.dimension.height {
            for x in 0..<mesh.dimension.width {
                
                let p =  mesh.target(to: box, at: (x: x, y: y)) 
        
                var knot:KnotNode
                if isInitilized {
                    knot = children[index] as! KnotNode
                    knot.bounds = box
                    if !knot.isPinned {
                        knot.position = p
                    }
                }                    
                else {
                    knot = KnotNode(bounds: box, radius: radius, name: "\(index)")
                    knot.position = p
                    addChild(knot)     
                    
                    if x == 0 && y == 0 {
                        knot.isAllwaysPinned = true
                    }
                    else if x == 0 && y == mesh.dimension.height-1 {
                        knot.isAllwaysPinned = true
                    }
                    else if x == mesh.dimension.width-1 && y == mesh.dimension.height-1 {
                        knot.isAllwaysPinned = true
                    }
                    else if x == mesh.dimension.width-1 && y == 0 {
                        knot.isAllwaysPinned = true
                    }                    
                }    
                index += 1
            }
        }
        isInitilized = true
    }
}
