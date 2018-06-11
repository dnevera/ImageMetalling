//
//  MSLSolver.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 11.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Foundation
import simd

public extension NSPoint {    
    public func convert(from box: NSRect) -> float2 {
        if box == .zero {
            return float2(0)
        }
        let point = self 
        let px = Float((point.x-box.origin.x)/(box.size.width))
        let py = Float((point.y-box.origin.y)/box.size.height)
        return float2(px,1-py)        
    }    
}

public extension float2 {
    public func convert(to box: NSRect) -> NSPoint {
        let px = box.origin.x + box.width  * CGFloat(self.x)
        let py = box.origin.y + box.height * CGFloat(1-self.y)
        return NSPoint(x: px, y: py)
    }
}

public class MSLSolver {
    
    public let alpha:Float
    public let count:Int
    public let point:float2
    public let p:[float2]
    public let q:[float2]
    public var w:[Float] = []
    public var weight:Float = Float.ulpOfOne
    public var pStar:float2 = float2()
    public var qStar:float2 = float2()
    public var pHat:[float2] = []
    public var qHat:[float2] = []
    
    
    public var M:float2x2 = float2x2(diagonal: float2(1))
    
    public init(point:float2, p:[float2], q:[float2], alpha:Float = 1) throws {
        if p.count != q.count {
            throw SolverError.diffSize
        }
        
        self.alpha = alpha
        self.count = p.count
        
        self.point = point
        self.p = p
        self.q = q
        
        solveW()
        solveStars()
        solveHat()
        solveM()    
                
        qHat = []
        pHat = []
    }
    
    public func value(at point:float2) -> float2 {
        
        if count <= 0 {
            return point;
        }
        
        return (point - pStar) * M + qStar    
    }
    
    private func solveW() {
        
        w = [Float](repeating: 0, count: count)
        weight = 0
        
        for i in 0..<count {
            
            //var d =  distance(p[i], point) // length(p[i] - point)
            //d = powf(d, 2*alpha) 
              
            let dx = p[i].x - point.x
            let dy = p[i].y - point.y
            var d = dx * dx + dy * dy
            
            if d < Float.ulpOfOne { d = Float.ulpOfOne}
            
            w[i] = 1.0 / d
            weight = weight + w[i]
        }
        
        if weight < Float.ulpOfOne { weight = Float.ulpOfOne }
    }
    
    private func solveStars() {
        pStar = float2(0)
        qStar = float2(0)
        
        for i in 0..<count {
            pStar += float2(w[i]) * p[i]
            qStar += float2(w[i]) * q[i]
        }
        
        pStar = pStar / weight                
        qStar = qStar / weight
    }
    
    private func solveHat(){        
        pHat = [float2](repeating: float2(0), count: count)
        qHat = [float2](repeating: float2(0), count: count)
        
        for i in 0..<count {            
            pHat[i] = p[i] - pStar
            qHat[i] = q[i] - qStar
        }
    }
    
    private func solveM(){
        M = Mi(point).inverse * Mj(point)
    }      
    
    private func Mj(_ value:float2) -> float2x2 {
        var mj = float2x2(0)
        for i in 0..<count {
            let p = w[i] * pHat[i]
            let q = qHat[i]
            let pt = float2x2(columns: (p, float2(0)))
            let qp = float2x2(rows: [q, float2(0)])
            let m = pt * qp
            mj += m
        }
        return mj
    }
    
    public func Mi(_ value:float2) -> float2x2 {
        var mj = float2x2(0)
        for i in 0..<count {
            let p = pHat[i]
            let pt = float2x2(columns: (p, float2(0)))
            let pp = w[i] * float2x2(rows: [p, float2(0)])
            let m = pt * pp
            mj += m
        }
        return mj
    }
        
    public enum SolverError:Error {
        case diffSize
    }
}
