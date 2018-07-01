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
    typealias Kind = MLSSolverKind
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
        
    public func process(controls:Controls, complete:((_ points:[float2])->Void)?=nil) {
        
        var result = [float2](repeating: float2(0), count: points.count)
        
        var cp = controls.p 
        var cq = controls.q
        let count = Int32(cp.count)        
        
        for (i,p) in points.enumerated() {            
            guard let mls = IMPMLSSolverBridge(p, source: &cp, destination: &cq, count: count, kind: controls.kind, alpha: controls.alpha) else {continue}
            result[i] = mls.value(p)
        }
        complete?(result)
    }    
}
