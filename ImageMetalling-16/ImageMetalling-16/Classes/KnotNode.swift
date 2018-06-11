//
//  KnotNode.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 06.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Cocoa
import SpriteKit

/// Просто sprite-нода для рисования области в которой мы читаем цвет
open class KnotNode: MNode {
                 
    public init(bounds:NSRect, radius:CGFloat) {
        super.init(bounds:bounds)
        let w = radius
        let rect = NSRect(origin: NSPoint(x:-w/2,y:-w/2), size: NSSize(width: w, height: w))
        path = CGPath(ellipseIn: rect, transform: nil)
    }    
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
