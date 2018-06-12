//
//  MSLSolver.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 11.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Foundation
import simd

protocol MLSSolverProtocol {
    var points:[float2] {set get}
    func process(controls:MLSControls, complete:((_ points:[float2])->Void)?)
}

public class MLSSolverCpp:MLSSolverProtocol {
    
    public typealias Kind = MLSSolverKind
    public typealias Controls=MLSControls

    public enum Error:Swift.Error {
        case diffSize
    }
    
    public var points:[float2] = [] 

    public init(points:[float2]?=nil ) {       
        if let s = points {
            self.points = [float2](s)
        }
    }
    
//    public init(point: float2, p:[float2], q:[float2], kind:MLSSolverKind = .affine, alpha:Float = 1.0) throws {
//        
//        if p.count != q.count {
//            throw Error.diffSize
//        }
//        
//        self.count = p.count
//        
//        self.p = [float2](p)
//        self.q = [float2](q)    
//        super.init(point, source: &self.p, destination: &self.q, count: Int32(p.count), kind: kind, alpha: alpha)
//    }
        
    public func process(controls:Controls, complete:((_ points:[float2])->Void)?=nil) {
        
        var result = [float2](repeating: float2(0), count: points.count)
        
        var cp = controls.p 
        var cq = controls.q
        let count = Int32(cp.count)        
        
        for (i,p) in points.enumerated() {            
            guard let mls = MLSSolverBridge(p, source: &cp, destination: &cq, count: count, kind: controls.kind, alpha: controls.alpha) else {continue}
            //solve(point: p, controls: controls)
            //result.append(mls.value(p))
            result[i] = mls.value(p)
        }
        complete?(result)
    }
    
//    public func value(at point:float2) -> float2 {
//        return self.value(point)
//    }
    
    //private var bridge:MLSSolverBridge!
    
    //public let count:Int
    //private var p = [float2]()
    //private var q = [float2]()
}

public class MLSSolverSwift: MLSSolverProtocol {
    
    public typealias Kind = MLSSolverKind
    public typealias Controls=MLSControls
        
    public var points:[float2] = [] 
    
    public init(points:[float2]?=nil ) {       
        if let s = points {
            self.points = [float2](s)
        }
    }
    
    public func process(controls:Controls, complete:((_ points:[float2])->Void)?=nil) {
        var result = [float2]()
        for p in points {
            solve(point: p, controls: controls)
            result.append(value(at: p))
        }
        complete?(result)
    }
    
    private func value(at point:float2) -> float2 {        
        if count <= 0 { return point }  
        return (point - pStar_) * M + qStar_    
    }
    
    private func solve(point:float2, controls:Controls) {
        self.kind = controls.kind
        self.alpha = controls.alpha
        self.count = controls.p.count
        
        self.point = point
        self.p = controls.p
        self.q = controls.q
        
        solveW()
        solveStars()
        solveHat()
        solveM()    
        
        qHat_ = []
        pHat_ = []        
    }
    
    private func solveW() {
        
        w_ = [Float](repeating: 0, count: count)
        weight_ = 0
        
        for i in 0..<count {
            
            var d =  powf(distance(p[i], point), 2*alpha)
                          
            if d < Float.ulpOfOne { d = Float.ulpOfOne}
            
            w_[i] = 1.0 / d
            weight_ = weight_ + w_[i]
        }
        
        if weight_ < Float.ulpOfOne { weight_ = Float.ulpOfOne }
    }
    
    private func solveStars() {
        pStar_ = float2(0)
        qStar_ = float2(0)
        
        for i in 0..<count {
            pStar_ += float2(w_[i]) * p[i]
            qStar_ += float2(w_[i]) * q[i]
        }
        
        pStar_ = pStar_ / weight_                
        qStar_ = qStar_ / weight_        
    }
    
    private func solveHat(){        
        pHat_ = [float2](repeating: float2(0), count: count)
        qHat_ = [float2](repeating: float2(0), count: count)
        mu_ = 0
        
        var _rmu1:Float = 0
        var _rmu2:Float = 0
        
        for i in 0..<count {      
            
            pHat_[i] = p[i] - pStar_                        
            qHat_[i] = q[i] - qStar_
            
            switch kind {            
            case .similarity:
                mu_ += similarityMu(index: i)
            case .rigid:
                _rmu1 += rigidMu1(index: i) 
                _rmu2 += rigidMu2(index: i) 
            default:
                break
            }
        }
        
        switch kind {            
        case .rigid:
            mu_ = sqrt(_rmu1*_rmu1 + _rmu2*_rmu2)  
        default:
            break
        }
        
        if mu_ < Float.ulpOfOne { mu_ = Float.ulpOfOne }
        
        mu_ = 1/mu_
    }
            
    private func solveM(){
        switch kind {
        case .affine:
            M = affineM()
        case .similarity, .rigid:
            M = similarityM(point)
        }
    }      
    
    fileprivate var w_:[Float] = []
    fileprivate var weight_:Float = Float.ulpOfOne
    fileprivate var pStar_:float2 = float2()
    fileprivate var qStar_:float2 = float2()
    fileprivate var pHat_:[float2] = []
    fileprivate var qHat_:[float2] = []
        
    fileprivate var mu_:Float = 1

    fileprivate var M:float2x2 = float2x2(diagonal: float2(1))
      
    private var kind:Kind = .affine
    private var alpha:Float = 1
    private var count:Int = 0
    private var point:float2 = float2()
    private var p:[float2] = []
    private var q:[float2] = []

}

//
// Affine transformation Matrix
//
extension MLSSolverSwift {
    
    private func affineMj() -> float2x2 {
        var m = float2x2(0)
        for i in 0..<count {

            let pt = float2x2(columns: (w_[i] * pHat_[i], float2(0)))
            let qp = float2x2(rows: [qHat_[i], float2(0)])

            m += pt * qp
        }
        return m
    }
    
    private func affineMi() -> float2x2 {
        var m = float2x2(0)
        for i in 0..<count {
            
            let pt =        float2x2(columns: (pHat_[i], float2(0)))
            let pp = w_[i] * float2x2(rows:    [pHat_[i], float2(0)])

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
extension MLSSolverSwift {    
    
    fileprivate func similarityMu(index i:Int) -> Float {
        return w_[i]*dot(pHat_[i], pHat_[i])
    }
    
    fileprivate func similarityM(_ value:float2) -> float2x2 {
        var m = float2x2(0)
        for i in 0..<count {
            
            let _p = w_[i] * float2x2(rows:    [pHat_[i], -1 * pHat_[i].slashReflect])            
            let _q =        float2x2(columns: (qHat_[i], -1 * qHat_[i].slashReflect))
                        
            m += _p * _q
        }
        return  mu_ * m 
    }
}

//
// Rigid transformation Matrix
//
extension MLSSolverSwift {     
    
    fileprivate func rigidMu1(index i:Int) -> Float {
        return w_[i]*dot(qHat_[i], pHat_[i])        
    }

    fileprivate func rigidMu2(index i:Int) -> Float {
        return w_[i]*dot(qHat_[i],  pHat_[i].slashReflect)        
    }

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

