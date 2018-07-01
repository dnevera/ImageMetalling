//
//  MLSControls.swift
//  ImageMetalling-16
//
//  Created by denis svinarchuk on 12.06.2018.
//  Copyright © 2018 ImageMetalling. All rights reserved.
//

import Foundation

public struct MLSControls {
    let p:[float2]
    let q:[float2]
    let kind:MLSSolverKind
    let alpha:Float
    
    public init(p: [float2], q: [float2], kind:MLSSolverKind = .affine, alpha:Float = 1.0){
        self.p = p
        self.q = q
        self.kind = kind
        self.alpha = alpha
    }
}
