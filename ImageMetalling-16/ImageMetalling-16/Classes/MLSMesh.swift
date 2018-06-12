//
//  MLSControlPoints.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 10.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Foundation
import simd
import IMProcessing
import Surge

public class MLSMesh {
        
    public let alpha:Float
    
    public let dimension:(width:Int,height:Int)
    
    public var sources:[float2] {
        return _sources
    }
    
    public var count:Int {
        return targets.count
    }
        
    public init(dimension: (width:Int,height:Int), alpha:Float = 1.0){
        
        self.alpha = alpha
        self.dimension = dimension
        
        _sources = [float2](repeating:float2(0), count:dimension.height*dimension.width)
        
        var index = 0
        for y in 0..<dimension.height {
            let py = Float(y)/Float(dimension.height-1) 
            for x in 0..<dimension.width {
                let px = Float(x)/Float(dimension.width-1) 
                let p = float2(px,py)
                _sources[index] = p
                index += 1 
            }
        }
        
        targets = [float2](_sources)                                             
    }
    
    public func reset(_ newTragers:[float2]?=nil) {
        targets = [float2](newTragers ?? sources)
    }
           
    subscript(index:Int) -> float2 {
        get {
            return targets[index]
        }
        set {
            targets[index] = newValue
        }
    }
    
    subscript(x:Int, y:Int) -> float2 {
        get {
            return targets[y*dimension.width + x]
        }
        set {
            targets[y*dimension.width + x] = newValue
        }
    }
    
    subscript(at position:(x:Int,y:Int)) -> float2 {
        get {
            return targets[position.y*dimension.width + position.x]
        }
        set {
            targets[position.y*dimension.width + position.x] = newValue
        }
    }
      
    public func source(to box: NSRect, at index:Int) -> NSPoint {
        let px = box.origin.x + box.width  * CGFloat(sources[index].x)
        let py = box.origin.y + box.height * CGFloat(1-sources[index].y)
        return NSPoint(x: px, y: py)
    }
    
    public func source(to box: NSRect, at position:(x:Int,y:Int)) -> NSPoint {
        return source(to: box, at: position.y * dimension.width + position.x)
    }  

    public func setTarget(point: NSPoint, from box: NSRect, at index:Int) {
        targets[index] = point.convert(from: box)         
    }
    
    public func setTarget(point: NSPoint, from box: NSRect, at position:(x:Int,y:Int)) {
        setTarget(point: point, from: box, at: position.y * dimension.width + position.x)
    }
    
    public func target(to box: NSRect, at index:Int) -> NSPoint {
        let px = box.origin.x + box.width  * CGFloat(targets[index].x)
        let py = box.origin.y + box.height * CGFloat(1-targets[index].y)
        return NSPoint(x: px, y: py)
    }
    
    public func target(to box: NSRect, at position:(x:Int,y:Int)) -> NSPoint {
        return target(to: box, at: position.y * dimension.width + position.x)
    } 
    
    private var targets:[float2] = []
    
    fileprivate var _sources:[float2]     
}
