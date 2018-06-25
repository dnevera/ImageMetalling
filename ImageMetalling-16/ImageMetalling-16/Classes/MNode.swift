//
//  MNode.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 06.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Cocoa
import SpriteKit


open class MNode: SKShapeNode {
    
    public var pinnedColor:NSColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1) { didSet{ update() } }
    
    public var color:NSColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0) { didSet{ update() } }
        
    public var isPinned:Bool = false { didSet{ update() } }
    
    public var bounds:NSRect { didSet{ update() } }
    
    public var relation:float2 {
        set{ update()  }
        get { return _relation }
    }
    
    open override var position: CGPoint {
        didSet{
            _relation = float2(Float((position.x-bounds.origin.x)/bounds.width),Float((position.y-bounds.origin.y)/bounds.height))
            if isPinned {
                fillColor = pinnedColor
            }
            else {
                fillColor = color
            }
        }
    }
    
    public init(bounds:NSRect) {
        self.bounds = bounds
        super.init()
        lineWidth = 2  
        strokeColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
        fillColor = color
    }
    
    open func update() {
        strokeColor = NSColor(red: 1, green: 1, blue: 1, alpha: isPinned ? 1 : 0.5)
        fillColor = color.withAlphaComponent(isPinned ? 1 : 0.5)
        position = NSPoint(x: CGFloat(_relation.x)*bounds.width+bounds.origin.x, y: CGFloat(_relation.y)*bounds.height+bounds.origin.y)
    }
    
    private lazy var _relation:float2 = float2(0) 
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }  
}
