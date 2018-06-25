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
                 
    public enum Shape{
        case circle
        case cross
    }
    
    public var radius:CGFloat = 10 {
        didSet{
            update()
        }
    }
    
    
    public var shape:Shape = .cross {
        didSet{
            update()
        }
    } 
    
    public override var isPinned: Bool {
        didSet{
            if isPinned == true {
                shape = .circle
            }
            update()
        }
    }
    
    public init(bounds:NSRect, radius:CGFloat, shape:Shape = .cross) {
        super.init(bounds:bounds)
        self.radius = radius
        self.shape = shape
        update()
    }    
    
    open override func update() {
        super.update()
        let w = radius
        switch shape {
        case .circle:
            let rect = NSRect(origin: NSPoint(x:-w/2,y:-w/2), size: NSSize(width: w, height: w))
            path = CGPath(ellipseIn: rect, transform: nil)            
        default:
            let p = CGMutablePath()
            p.move(to: NSPoint(x:-w/2,y:0))
            p.addLine(to: NSPoint(x:w/2,y:0))
            p.move(to: NSPoint(x:0,y:-w/2))
            p.addLine(to: NSPoint(x:0,y:w/2))
            path =  p            
        }        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
