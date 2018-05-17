//
//  PatchNode.swift
//  ImageMetalling-14
//
//  Created by denis svinarchuk on 16.05.2018.
//  Copyright © 2018 Dehancer. All rights reserved.
//

import Cocoa
import SpriteKit

class PatchNode: SKShapeNode {

    init(size:CGFloat) {
        super.init()
        lineWidth = 2  
        strokeColor = NSColor(red: 0.5, green: 0.5, blue: 1, alpha: 1) 
        fillColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0)
        let w = size
        let rect = NSRect(origin: NSPoint(x:-w/2,y:-w/2), size: NSSize(width: w, height: w))
        path     = CGPath(ellipseIn: rect, transform: nil)        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }  
}
