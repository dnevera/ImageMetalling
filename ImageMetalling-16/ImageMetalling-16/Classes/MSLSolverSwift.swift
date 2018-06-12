//
//  MSLSolver.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 11.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Foundation
import simd

public class _MLSSolver: MLSSolverBridge {    
    
    public enum Error:Swift.Error {
        case diffSize
    }
    
    public init(point: float2, p:[float2], q:[float2], kind:MLSSolverKind = .affine, alpha:Float = 1.0) throws {
        
        if p.count != q.count {
            throw Error.diffSize
        }
        
        self.count = p.count
        
        self.p = [float2](p)
        self.q = [float2](q)    
        super.init(point, source: &self.p, destination: &self.q, count: Int32(p.count), kind: kind, alpha: alpha)
    }
        
    public func value(at point:float2) -> float2 {
        return self.value(point)
    }
    
    public let count:Int
    private var p = [float2]()
    private var q = [float2]()
}

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

private extension float2 {
    var slashReflect:float2 {
        return float2(-y,x)
    }
}

public class MSLSolverSwift {
    
    public typealias Kind = MLSSolverKind
    
    public enum Error:Swift.Error {
        case diffSize
    }
    
    public let kind:Kind
    public let alpha:Float
    public let count:Int
    public let point:float2
    public let p:[float2]
    public let q:[float2]
    
    public init(point:float2, p:[float2], q:[float2], kind:Kind = .affine, alpha:Float = 1) throws {
        if p.count != q.count {
            throw Error.diffSize
        }
        
        self.kind = kind
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
        if count <= 0 { return point }  
        return (point - pStar) * M + qStar    
    }
    
    private func solveW() {
        
        w = [Float](repeating: 0, count: count)
        weight = 0
        
        for i in 0..<count {
            
            var d =  powf(distance(p[i], point), 2*alpha)
                          
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
        mu = 0
        
        var _rmu1:Float = 0
        var _rmu2:Float = 0
        
        for i in 0..<count {      
            
            pHat[i] = p[i] - pStar                        
            qHat[i] = q[i] - qStar
            
            switch kind {            
            case .similarity:
                mu += similarityMu(index: i)
            case .rigid:
                _rmu1 += rigidMu1(index: i) 
                _rmu2 += rigidMu2(index: i) 
            default:
                break
            }
        }
        
        switch kind {            
        case .rigid:
            mu = sqrt(_rmu1*_rmu1 + _rmu2*_rmu2)  
        default:
            break
        }
        
        if mu < Float.ulpOfOne { mu = Float.ulpOfOne }
        
        mu = 1/mu
    }
            
    private func solveM(){
        switch kind {
        case .affine:
            M = affineM()
        case .similarity, .rigid:
            M = similarityM(point)
        }
    }      
             
    fileprivate var w:[Float] = []
    fileprivate var weight:Float = Float.ulpOfOne
    fileprivate var pStar:float2 = float2()
    fileprivate var qStar:float2 = float2()
    fileprivate var pHat:[float2] = []
    fileprivate var qHat:[float2] = []
        
    fileprivate var mu:Float = 1

    fileprivate var M:float2x2 = float2x2(diagonal: float2(1))
            
}

//
// Affine transformation Matrix
//
extension MSLSolverSwift {
    
    private func affineMj() -> float2x2 {
        var m = float2x2(0)
        for i in 0..<count {

            let pt = float2x2(columns: (w[i] * pHat[i], float2(0)))
            let qp = float2x2(rows: [qHat[i], float2(0)])

            m += pt * qp
        }
        return m
    }
    
    private func affineMi() -> float2x2 {
        var m = float2x2(0)
        for i in 0..<count {
            
            let pt =        float2x2(columns: (pHat[i], float2(0)))
            let pp = w[i] * float2x2(rows:    [pHat[i], float2(0)])

            m += pt * pp
        }
        return m
    }
    
    fileprivate func affineM() -> float2x2 {
        return affineMi().inverse * affineMj();
    }
}

//
// Similarity transformation Matrix
//
extension MSLSolverSwift {    
    
    fileprivate func similarityMu(index i:Int) -> Float {
        return w[i]*dot(pHat[i], pHat[i])
    }
    
    fileprivate func similarityM(_ value:float2) -> float2x2 {
        var m = float2x2(0)
        for i in 0..<count {
            
            let _p = w[i] * float2x2(rows:    [pHat[i], -1 * pHat[i].slashReflect])            
            let _q =        float2x2(columns: (qHat[i], -1 * qHat[i].slashReflect))
                        
            m += _p * _q
        }
        return  mu * m 
    }
}

//
// Rigid transformation Matrix
//
extension MSLSolverSwift {     
    
    fileprivate func rigidMu1(index i:Int) -> Float {
        return w[i]*dot(qHat[i], pHat[i])        
    }

    fileprivate func rigidMu2(index i:Int) -> Float {
        return w[i]*dot(qHat[i],  pHat[i].slashReflect)        
    }

}

