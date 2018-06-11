//
//  KnotRelation.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 06.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Cocoa
import SpriteKit

open class KnotRelationNode: MNode {
    
    public init(bounds:NSRect, start:NSPoint, end:NSPoint) {
        super.init(bounds:bounds)
        let p = CGMutablePath()
        p.move(to: start)
        p.addLine(to: end)        
        path = p
    }    
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
